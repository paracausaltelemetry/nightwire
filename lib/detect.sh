#!/usr/bin/env bash

ctf_detect_platform() {
  if [[ ! -r /etc/os-release ]]; then
    ctf_die "Cannot detect distro because /etc/os-release is missing."
  fi

  # shellcheck disable=SC1091
  source /etc/os-release
  DISTRO_ID="${ID:-unknown}"
  DISTRO_ID_LIKE="${ID_LIKE:-}"
  DISTRO_VERSION="${VERSION_ID:-unknown}"
  DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID}"

  case "$DISTRO_ID" in
    kali) DISTRO_FAMILY="kali" ;;
    parrot | parrotos) DISTRO_FAMILY="parrot" ;;
    ubuntu) DISTRO_FAMILY="ubuntu" ;;
    debian) DISTRO_FAMILY="debian" ;;
    *)
      if [[ "$DISTRO_ID_LIKE" == *debian* ]]; then
        DISTRO_FAMILY="debian"
      else
        ctf_die "Unsupported distro '$DISTRO_NAME'. This bootstrapper targets Kali, Parrot, Ubuntu, and Debian-family releases."
      fi
      ;;
  esac

  ctf_detect_desktop
  ctf_detect_virtualization
  ctf_info "Detected distro: $DISTRO_NAME ($DISTRO_FAMILY)"
  ctf_info "Detected desktop: $DETECTED_DESKTOP"
  ctf_info "Detected virtualization: $VM_TYPE"
}

ctf_detect_desktop() {
  local desktop="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"
  desktop="$(printf '%s' "$desktop" | tr '[:upper:]' '[:lower:]')"

  case "$desktop" in
    *xfce*) DETECTED_DESKTOP="xfce" ;;
    *gnome* | *ubuntu*) DETECTED_DESKTOP="gnome" ;;
    *kde* | *plasma*) DETECTED_DESKTOP="kde" ;;
    *mate*) DETECTED_DESKTOP="mate" ;;
    *)
      if pgrep -x xfce4-session >/dev/null 2>&1; then
        DETECTED_DESKTOP="xfce"
      elif pgrep -x gnome-shell >/dev/null 2>&1; then
        DETECTED_DESKTOP="gnome"
      elif pgrep -x plasmashell >/dev/null 2>&1; then
        DETECTED_DESKTOP="kde"
      elif pgrep -x mate-session >/dev/null 2>&1; then
        DETECTED_DESKTOP="mate"
      else
        DETECTED_DESKTOP="none"
      fi
      ;;
  esac

  if [[ "$DETECTED_DESKTOP" != "none" ]]; then
    GUI_PRESENT=1
  fi
}

ctf_detect_virtualization() {
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    VM_TYPE="$(systemd-detect-virt --vm 2>/dev/null || true)"
    VM_TYPE="${VM_TYPE:-none}"
  else
    VM_TYPE="unknown"
  fi
}

ctf_prepare_privilege() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    SUDO_CMD=()
    return 0
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    ctf_die "sudo is required when running as a non-root user."
  fi

  ctf_info "Requesting sudo credentials."
  sudo -v
  SUDO_CMD=(sudo)
}

ctf_resolve_target_user() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    TARGET_USER="${SUDO_USER:-root}"
  else
    TARGET_USER="$(id -un)"
  fi

  if ! getent passwd "$TARGET_USER" >/dev/null; then
    ctf_die "Cannot resolve target user '$TARGET_USER'."
  fi

  TARGET_HOME="$(getent passwd "$TARGET_USER" | awk -F: '{print $6}')"
  if [[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]]; then
    ctf_die "Cannot resolve home directory for target user '$TARGET_USER'."
  fi

  if [[ "$TARGET_USER" == "root" ]]; then
    ctf_warn "Target user is root. Shell and desktop customization will be applied to /root."
  fi

  if [[ -z "$WORKSPACE_DIR" ]]; then
    WORKSPACE_DIR="$TARGET_HOME/ctf"
  elif [[ "$WORKSPACE_DIR" == "~"* ]]; then
    WORKSPACE_DIR="$TARGET_HOME${WORKSPACE_DIR#~}"
  fi

  ctf_info "Target user: $TARGET_USER ($TARGET_HOME)"
  ctf_info "Workspace root: $WORKSPACE_DIR"
}

ctf_preflight_checks() {
  for required in apt-get apt-cache dpkg awk sed grep; do
    command -v "$required" >/dev/null 2>&1 || ctf_die "Missing required command: $required"
  done

  local required_mib=4096
  case "$PROFILE" in
    standard) required_mib=12288 ;;
    full) required_mib=40960 ;;
  esac

  local available_mib
  available_mib="$(df -Pm / | awk 'NR==2 {print $4}')"
  if [[ "$available_mib" =~ ^[0-9]+$ ]] && ((available_mib < required_mib)); then
    ctf_warn "Low disk space: ${available_mib}MiB available, ${required_mib}MiB recommended for profile '$PROFILE'."
    if [[ "$PROFILE" == "full" ]] && ! ((YES)); then
      ctf_die "Full profile requires more free space. Re-run with --yes to override."
    fi
  fi

  if [[ "$DESKTOP_MODE" == "auto" ]]; then
    SELECTED_DESKTOP="$DETECTED_DESKTOP"
  else
    SELECTED_DESKTOP="$DESKTOP_MODE"
  fi
}

ctf_is_kali() {
  [[ "$DISTRO_FAMILY" == "kali" ]]
}

ctf_is_parrot() {
  [[ "$DISTRO_FAMILY" == "parrot" ]]
}

ctf_is_debian_or_ubuntu() {
  [[ "$DISTRO_FAMILY" == "debian" || "$DISTRO_FAMILY" == "ubuntu" ]]
}
