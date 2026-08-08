#!/usr/bin/env bash

ctf_wait_for_apt_locks() {
  if ! command -v fuser >/dev/null 2>&1; then
    return 0
  fi

  local locks=(
    /var/lib/dpkg/lock
    /var/lib/dpkg/lock-frontend
    /var/lib/apt/lists/lock
    /var/cache/apt/archives/lock
  )
  local waited=0

  while fuser "${locks[@]}" >/dev/null 2>&1; do
    if ((waited == 0)); then
      ctf_info "Waiting for apt/dpkg locks to clear."
    fi
    sleep 5
    waited=$((waited + 5))
    if ((waited >= 600)); then
      ctf_die "Timed out waiting for apt/dpkg locks."
    fi
  done
}

ctf_apt_update_once() {
  if ((APT_UPDATED)); then
    return 0
  fi
  ctf_wait_for_apt_locks
  ctf_run_root env DEBIAN_FRONTEND=noninteractive apt-get update
  APT_UPDATED=1
}

ctf_package_available() {
  local package="$1"
  # apt-cache show succeeds for transitional/virtual packages that have no
  # installation candidate, which then break `apt-get install`. Require a real
  # candidate via apt-cache policy instead.
  local candidate
  candidate="$(apt-cache policy "$package" 2>/dev/null | awk -F': ' '/^[[:space:]]*Candidate:/ {print $2; exit}')"
  [[ -n "$candidate" && "$candidate" != "(none)" ]]
}

ctf_install_packages() {
  local requested=("$@")
  local available=()
  local package

  if ((${#requested[@]} == 0)); then
    return 0
  fi

  ctf_apt_update_once
  for package in "${requested[@]}"; do
    [[ -z "$package" ]] && continue
    if ctf_package_available "$package"; then
      available+=("$package")
    else
      SKIPPED_PACKAGES+=("$package")
      ctf_warn "Package unavailable on $DISTRO_NAME: $package"
    fi
  done

  if ((${#available[@]} == 0)); then
    ctf_warn "No requested packages are available for this section."
    return 0
  fi

  ctf_info "Installing ${#available[@]} apt package(s)..."
  ctf_wait_for_apt_locks
  # Try the batch first; if it fails, retry one-by-one so a single bad package
  # cannot abort the whole bootstrap. (Inside `if`, the ERR trap is suppressed.)
  if ctf_run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${available[@]}"; then
    INSTALLED_PACKAGE_GROUPS+=("${available[*]}")
    return 0
  fi

  ctf_warn "Batch install failed; retrying packages individually."
  local pkg
  for pkg in "${available[@]}"; do
    ctf_wait_for_apt_locks
    if ctf_run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"; then
      INSTALLED_PACKAGE_GROUPS+=("$pkg")
    else
      ctf_warn "Failed to install apt package: $pkg"
      SKIPPED_PACKAGES+=("$pkg")
    fi
  done
}

ctf_enable_service_if_present() {
  local service="$1"
  if ! command -v systemctl >/dev/null 2>&1; then
    ctf_warn "systemctl unavailable; cannot enable $service."
    return 0
  fi

  if systemctl list-unit-files "$service.service" >/dev/null 2>&1; then
    ctf_try_root systemctl enable --now "$service"
  else
    ctf_warn "Service not present: $service"
  fi
}
