#!/usr/bin/env bash

ctf_usage() {
  cat <<'USAGE'
Usage: ./install.sh [options]

Options:
  --config PATH                      Load YAML-style config file before CLI overrides.
  --profile light|standard|full       Base package profile. Interactive menu if omitted.
  --extras LIST                       Extra profiles: web,pwn,rev,forensics,osint,wireless,bugbounty,cloud,ad,malware,all.
  --shell bash|zsh|both               Shell customization target. Default: both.
  --desktop auto|xfce|gnome|kde|mate|none
                                      Desktop customization target. Default: auto.
  --runtime system|mise|none          Runtime strategy. Default: system.
  --browser proxy|basic|none          Browser/proxy helper setup. Default: proxy.
  --labs local|all|none               Local Docker lab assets to install. Default: local.
  --workspace-dir PATH                Default workspace root. Default: ~/ctf.
  --assets-url URL                    GitHub release archive, raw asset base URL, or tarball URL.
  --cache-dir PATH                    Offline cache (see: nightwire cache prepare) for plugin/font downloads.
  --no-remote-installers              Forbid curl|sh installers (starship fallback, mise); apt/git only.
  --dry-run                           Print actions without changing the system.
  --yes                               Use defaults and skip confirmations.
  --no-reboot                         Do not suggest reboot at the end.
  --log-file PATH                     Write detailed log to PATH.
  --only a,b,c                        Run only selected sections.
  --skip a,b,c                        Skip selected sections.
  -h, --help                          Show this help.

Sections:
  runtime, packages, assets, command, workspace, browser, labs, vmware, shell, desktop, validate

Examples:
  ./install.sh
  ./install.sh --profile standard --extras bugbounty,web --shell both --desktop auto
  ./install.sh --profile full --extras all --runtime mise --yes --assets-url https://example.com/assets.tar.gz
USAGE
}

ctf_parse_args() {
  local -a original_args=("$@")
  ctf_parse_config_arg_only "$@"
  if [[ -n "$CONFIG_FILE" ]]; then
    ctf_load_config_file "$CONFIG_FILE"
  fi

  set -- "${original_args[@]}"
  while (($#)); do
    case "$1" in
      --config)
        [[ $# -ge 2 ]] || ctf_die "--config requires a value."
        CONFIG_FILE="${2:-}"
        shift 2
        ;;
      --config=*)
        CONFIG_FILE="${1#*=}"
        shift
        ;;
      --profile)
        [[ $# -ge 2 ]] || ctf_die "--profile requires a value."
        PROFILE="${2:-}"
        shift 2
        ;;
      --profile=*)
        PROFILE="${1#*=}"
        shift
        ;;
      --extras)
        [[ $# -ge 2 ]] || ctf_die "--extras requires a value."
        EXTRA_PROFILES="${2:-}"
        shift 2
        ;;
      --extras=*)
        EXTRA_PROFILES="${1#*=}"
        shift
        ;;
      --shell)
        [[ $# -ge 2 ]] || ctf_die "--shell requires a value."
        SHELL_MODE="${2:-}"
        shift 2
        ;;
      --shell=*)
        SHELL_MODE="${1#*=}"
        shift
        ;;
      --desktop)
        [[ $# -ge 2 ]] || ctf_die "--desktop requires a value."
        DESKTOP_MODE="${2:-}"
        shift 2
        ;;
      --desktop=*)
        DESKTOP_MODE="${1#*=}"
        shift
        ;;
      --runtime)
        [[ $# -ge 2 ]] || ctf_die "--runtime requires a value."
        RUNTIME_MODE="${2:-}"
        shift 2
        ;;
      --runtime=*)
        RUNTIME_MODE="${1#*=}"
        shift
        ;;
      --browser)
        [[ $# -ge 2 ]] || ctf_die "--browser requires a value."
        BROWSER_MODE="${2:-}"
        shift 2
        ;;
      --browser=*)
        BROWSER_MODE="${1#*=}"
        shift
        ;;
      --labs)
        [[ $# -ge 2 ]] || ctf_die "--labs requires a value."
        LAB_MODE="${2:-}"
        shift 2
        ;;
      --labs=*)
        LAB_MODE="${1#*=}"
        shift
        ;;
      --workspace-dir)
        [[ $# -ge 2 ]] || ctf_die "--workspace-dir requires a value."
        WORKSPACE_DIR="${2:-}"
        shift 2
        ;;
      --workspace-dir=*)
        WORKSPACE_DIR="${1#*=}"
        shift
        ;;
      --assets-url)
        [[ $# -ge 2 ]] || ctf_die "--assets-url requires a value."
        ASSETS_URL="${2:-}"
        shift 2
        ;;
      --assets-url=*)
        ASSETS_URL="${1#*=}"
        shift
        ;;
      --cache-dir)
        [[ $# -ge 2 ]] || ctf_die "--cache-dir requires a value."
        CACHE_DIR="${2:-}"
        shift 2
        ;;
      --cache-dir=*)
        CACHE_DIR="${1#*=}"
        shift
        ;;
      --no-remote-installers)
        REMOTE_INSTALLERS=0
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --yes | -y)
        YES=1
        shift
        ;;
      --no-reboot)
        NO_REBOOT=1
        shift
        ;;
      --log-file)
        [[ $# -ge 2 ]] || ctf_die "--log-file requires a value."
        LOG_FILE="${2:-}"
        shift 2
        ;;
      --log-file=*)
        LOG_FILE="${1#*=}"
        shift
        ;;
      --only)
        [[ $# -ge 2 ]] || ctf_die "--only requires a value."
        ONLY_SECTIONS="${2:-}"
        shift 2
        ;;
      --only=*)
        ONLY_SECTIONS="${1#*=}"
        shift
        ;;
      --skip)
        [[ $# -ge 2 ]] || ctf_die "--skip requires a value."
        SKIP_SECTIONS="${2:-}"
        shift 2
        ;;
      --skip=*)
        SKIP_SECTIONS="${1#*=}"
        shift
        ;;
      -h | --help)
        ctf_usage
        exit 0
        ;;
      *)
        ctf_die "Unknown option: $1"
        ;;
    esac
  done
}

ctf_parse_config_arg_only() {
  while (($#)); do
    case "$1" in
      --config)
        [[ $# -ge 2 ]] || ctf_die "--config requires a value."
        CONFIG_FILE="${2:-}"
        shift 2
        ;;
      --config=*)
        CONFIG_FILE="${1#*=}"
        shift
        ;;
      *)
        shift
        ;;
    esac
  done
}

ctf_load_config_file() {
  local path="$1"
  [[ -f "$path" ]] || ctf_die "Config file not found: $path"

  local line key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    [[ "$line" == *:* ]] || continue
    key="${line%%:*}"
    value="${line#*:}"
    key="$(printf '%s' "$key" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    value="$(printf '%s' "$value" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^["'\'']//; s/["'\'']$//')"

    case "$key" in
      profile) PROFILE="$value" ;;
      extras) EXTRA_PROFILES="$value" ;;
      shell) SHELL_MODE="$value" ;;
      desktop) DESKTOP_MODE="$value" ;;
      runtime) RUNTIME_MODE="$value" ;;
      browser) BROWSER_MODE="$value" ;;
      labs) LAB_MODE="$value" ;;
      workspace_dir) WORKSPACE_DIR="$value" ;;
      assets_url) ASSETS_URL="$value" ;;
      cache_dir) CACHE_DIR="$value" ;;
      log_file) LOG_FILE="$value" ;;
      only) ONLY_SECTIONS="$value" ;;
      skip) SKIP_SECTIONS="$value" ;;
      dry_run) [[ "$value" =~ ^(true|yes|1)$ ]] && DRY_RUN=1 ;;
      yes) [[ "$value" =~ ^(true|yes|1)$ ]] && YES=1 ;;
      no_reboot) [[ "$value" =~ ^(true|yes|1)$ ]] && NO_REBOOT=1 ;;
      remote_installers) [[ "$value" =~ ^(false|no|0)$ ]] && REMOTE_INSTALLERS=0 ;;
      *) ctf_warn "Ignoring unknown config key: $key" ;;
    esac
  done <"$path"
}

ctf_prompt_choice() {
  local prompt="$1"
  local default="$2"
  shift 2
  local choices=("$@")
  local value

  printf '\n%s\n' "$prompt"
  local i=1
  for choice in "${choices[@]}"; do
    printf '  %d) %s%s\n' "$i" "$choice" "$([[ "$choice" == "$default" ]] && printf ' (default)')"
    ((i++))
  done
  printf '> '
  read -r value
  value="${value:-$default}"

  if [[ "$value" =~ ^[0-9]+$ ]] && ((value >= 1 && value <= ${#choices[@]})); then
    printf '%s\n' "${choices[$((value - 1))]}"
    return 0
  fi

  for choice in "${choices[@]}"; do
    if [[ "$value" == "$choice" ]]; then
      printf '%s\n' "$choice"
      return 0
    fi
  done

  ctf_die "Invalid choice: $value"
}

ctf_interactive_defaults() {
  if [[ -z "$PROFILE" ]]; then
    if ((YES)) || [[ ! -t 0 ]]; then
      PROFILE="standard"
    else
      PROFILE="$(ctf_prompt_choice "Select package profile:" "standard" light standard full)"
    fi
  fi

  if [[ -z "$SHELL_MODE" ]]; then
    if ((YES)) || [[ ! -t 0 ]]; then
      SHELL_MODE="both"
    else
      SHELL_MODE="$(ctf_prompt_choice "Select shell customization:" "both" bash zsh both)"
    fi
  fi

  if [[ -z "$DESKTOP_MODE" ]]; then
    DESKTOP_MODE="auto"
  fi
}

ctf_validate_options() {
  case "$PROFILE" in
    light | standard | full) ;;
    *) ctf_die "Invalid --profile '$PROFILE'. Use light, standard, or full." ;;
  esac

  case "$SHELL_MODE" in
    bash | zsh | both) ;;
    *) ctf_die "Invalid --shell '$SHELL_MODE'. Use bash, zsh, or both." ;;
  esac

  case "$DESKTOP_MODE" in
    auto | xfce | gnome | kde | mate | none) ;;
    *) ctf_die "Invalid --desktop '$DESKTOP_MODE'. Use auto, xfce, gnome, kde, mate, or none." ;;
  esac

  case "$RUNTIME_MODE" in
    system | mise | none) ;;
    *) ctf_die "Invalid --runtime '$RUNTIME_MODE'. Use system, mise, or none." ;;
  esac

  case "$BROWSER_MODE" in
    proxy | basic | none) ;;
    *) ctf_die "Invalid --browser '$BROWSER_MODE'. Use proxy, basic, or none." ;;
  esac

  case "$LAB_MODE" in
    local | all | none) ;;
    *) ctf_die "Invalid --labs '$LAB_MODE'. Use local, all, or none." ;;
  esac

  ctf_validate_extra_profiles "$EXTRA_PROFILES"
  ctf_validate_sections "$ONLY_SECTIONS"
  ctf_validate_sections "$SKIP_SECTIONS"
}

ctf_validate_extra_profiles() {
  local profiles="$1"
  [[ -z "$profiles" ]] && return 0

  local profile
  local -a _ctf_profiles
  IFS=',' read -r -a _ctf_profiles <<<"$profiles"
  for profile in "${_ctf_profiles[@]}"; do
    case "$profile" in
      web | pwn | rev | forensics | osint | wireless | bugbounty | cloud | ad | malware | all) ;;
      *) ctf_die "Invalid extra profile '$profile'. Use web, pwn, rev, forensics, osint, wireless, bugbounty, cloud, ad, malware, or all." ;;
    esac
  done
}

ctf_validate_sections() {
  local sections="$1"
  [[ -z "$sections" ]] && return 0

  local section
  local -a _ctf_sections
  IFS=',' read -r -a _ctf_sections <<<"$sections"
  for section in "${_ctf_sections[@]}"; do
    case "$section" in
      runtime | packages | assets | command | workspace | browser | labs | vmware | shell | desktop | validate) ;;
      *) ctf_die "Invalid section '$section'. Use runtime, packages, assets, command, workspace, browser, labs, vmware, shell, desktop, or validate." ;;
    esac
  done
}

ctf_csv_contains() {
  local csv="$1"
  local needle="$2"
  [[ ",$csv," == *",$needle,"* ]]
}

ctf_section_enabled() {
  local section="$1"
  if [[ -n "$ONLY_SECTIONS" ]] && ! ctf_csv_contains "$ONLY_SECTIONS" "$section"; then
    return 1
  fi
  if [[ -n "$SKIP_SECTIONS" ]] && ctf_csv_contains "$SKIP_SECTIONS" "$section"; then
    return 1
  fi
  return 0
}

ctf_count_sections() {
  local section
  CTF_SECTION_TOTAL=0
  CTF_SECTION_NUM=0
  for section in runtime packages assets command workspace browser labs vmware shell desktop validate; do
    if ctf_section_enabled "$section"; then
      CTF_SECTION_TOTAL=$((CTF_SECTION_TOTAL + 1))
    fi
  done
}

ctf_run_section() {
  local name="$1"
  local title="$2"
  local fn="$3"
  if ctf_section_enabled "$name"; then
    CTF_SECTION_NUM=$((CTF_SECTION_NUM + 1))
    ctf_section "$title"
    "$fn"
  else
    ctf_info "Skipping section: $title"
  fi
}

ctf_confirm_scope() {
  if ((YES)) || ((DRY_RUN)); then
    return 0
  fi

  if [[ "$PROFILE" == "full" ]]; then
    printf '\nThe full profile can install many gigabytes of tools and metapackages. Continue? [y/N] '
    local answer
    read -r answer
    case "$answer" in
      y | Y | yes | YES) ;;
      *) ctf_die "Aborted before full profile install." ;;
    esac
  fi

  if [[ "$SHELL_MODE" == "zsh" ]]; then
    ctf_warn "The zsh-only mode may change the login shell after confirmation."
  fi
}
