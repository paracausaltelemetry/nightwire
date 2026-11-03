#!/usr/bin/env bash
# Resolve every profile/extra combination against this machine's apt sources
# and report packages with no install candidate. Run as root in a clean
# container of the target distro (CI does this for Kali, Debian and Ubuntu).
#
#   tools/check-packages.sh [--no-update] [--strict-extras LIST] [--remote]
#
# --strict-extras LIST  Fail when packages from these extras are missing
#                       (unless listed in tools/package-allowlist/<family>.txt).
# --remote              Also check pipx names on PyPI and Go modules on the
#                       Go module proxy.
set -Eeuo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SCRIPT_ROOT

# shellcheck source=lib/config.sh
source "$SCRIPT_ROOT/lib/config.sh"
# shellcheck source=lib/logging.sh
source "$SCRIPT_ROOT/lib/logging.sh"
# shellcheck source=lib/args.sh
source "$SCRIPT_ROOT/lib/args.sh"
# shellcheck source=lib/detect.sh
source "$SCRIPT_ROOT/lib/detect.sh"
# shellcheck source=lib/apt.sh
source "$SCRIPT_ROOT/lib/apt.sh"
# shellcheck source=lib/packages.sh
source "$SCRIPT_ROOT/lib/packages.sh"

update=1
strict_extras=""
remote=0
while (($#)); do
  case "$1" in
    --no-update) update=0 ;;
    --strict-extras)
      strict_extras="${2:-}"
      shift
      ;;
    --remote) remote=1 ;;
    *)
      printf 'usage: %s [--no-update] [--strict-extras LIST] [--remote]\n' "$0" >&2
      exit 2
      ;;
  esac
  shift
done

ctf_init_defaults
ctf_detect_platform >/dev/null

if ((update)); then
  DEBIAN_FRONTEND=noninteractive apt-get update -qq
fi

allowlist="$SCRIPT_ROOT/tools/package-allowlist/$DISTRO_FAMILY.txt"
declare -A allowed=()
if [[ -f "$allowlist" ]]; then
  while IFS= read -r line; do
    line="${line%%#*}"
    line="${line//[[:space:]]/}"
    [[ -n "$line" ]] && allowed[$line]=1
  done <"$allowlist"
fi

summary="${GITHUB_STEP_SUMMARY:-/dev/null}"
failures=0
declare -A checked=()

# check_set LABEL STRICT(0|1)
check_set() {
  local label="$1" strict="$2" pkg
  local -a missing=()
  for pkg in "${PROFILE_PACKAGES[@]}"; do
    [[ -n "${checked[$pkg]+x}" && "${checked[$pkg]}" == ok ]] && continue
    if [[ -z "${checked[$pkg]+x}" ]]; then
      if ctf_package_available "$pkg"; then checked[$pkg]=ok; continue; fi
      checked[$pkg]=missing
    fi
    missing+=("$pkg")
  done

  printf '%-28s %3d packages, %d missing\n' "$label" "${#PROFILE_PACKAGES[@]}" "${#missing[@]}"
  ((${#missing[@]})) || return 0
  printf '  missing: %s\n' "${missing[*]}"
  printf -- '- **%s** missing on %s: `%s`\n' "$label" "$DISTRO_NAME" "${missing[*]}" >>"$summary"

  if ((strict)); then
    for pkg in "${missing[@]}"; do
      if [[ -z "${allowed[$pkg]+x}" ]]; then
        printf '::error title=Missing package::%s (%s) has no candidate on %s\n' "$pkg" "$label" "$DISTRO_NAME"
        failures=$((failures + 1))
      fi
    done
  fi
}

printf '## Package availability: %s\n\n' "$DISTRO_NAME" >>"$summary"
printf 'Checking package availability on %s (%s)\n\n' "$DISTRO_NAME" "$DISTRO_FAMILY"

for profile in light standard full; do
  EXTRA_PROFILES=""
  ctf_resolve_profile_packages "$profile"
  check_set "profile:$profile" 0
done

for extra in web pwn rev forensics osint wireless bugbounty cloud ad malware cpts; do
  # Check the extra's own packages, not the light base it is layered on.
  EXTRA_PROFILES="$extra"
  ctf_resolve_profile_packages light
  declare -A base=()
  for pkg in "${LIGHT_PACKAGES[@]}"; do base[$pkg]=1; done
  filtered=()
  for pkg in "${PROFILE_PACKAGES[@]}"; do
    [[ -z "${base[$pkg]+x}" ]] && filtered+=("$pkg")
  done
  PROFILE_PACKAGES=("${filtered[@]}")
  unset base

  strict=0
  [[ -n "$strict_extras" ]] && ctf_csv_contains "$strict_extras" "$extra" && strict=1
  check_set "extra:$extra" "$strict"
done

if ((remote)); then
  printf '\nChecking pipx names on PyPI and Go modules on proxy.golang.org\n'
  EXTRA_PROFILES="all"
  ctf_resolve_profile_packages full

  for tool in "${PIPX_TOOLS[@]}"; do
    [[ "$tool" == git+* ]] && continue
    if ! curl -fs --max-time 20 -o /dev/null "https://pypi.org/pypi/$tool/json"; then
      printf '::error title=Unknown PyPI package::%s\n' "$tool"
      failures=$((failures + 1))
    fi
  done

  for entry in "${GO_TOOLS[@]}"; do
    module_path="${entry#*|}"
    version="${module_path##*@}"
    path="${module_path%@*}"
    found=0
    # The module root is a prefix of the package path; walk up until the proxy knows it.
    while [[ "$path" == */*/* ]]; do
      encoded="$(printf '%s' "$path" | sed -E 's/([A-Z])/!\L\1/g')"
      if curl -fs --max-time 20 -o /dev/null "https://proxy.golang.org/$encoded/@v/$version.info"; then
        found=1
        break
      fi
      path="${path%/*}"
    done
    if ((!found)); then
      printf '::error title=Unknown Go module version::%s\n' "$module_path"
      failures=$((failures + 1))
    fi
  done
fi

if ((failures)); then
  printf '\n%d problem(s) found.\n' "$failures"
  exit 1
fi
printf '\nOK\n'
