#!/usr/bin/env bash

ctf_init_defaults() {
  NIGHTWIRE_VERSION="0.1.0"
  CONFIG_FILE=""
  PROFILE=""
  EXTRA_PROFILES=""
  SHELL_MODE=""
  DESKTOP_MODE=""
  RUNTIME_MODE="system"
  BROWSER_MODE="proxy"
  LAB_MODE="local"
  WORKSPACE_DIR=""
  ASSETS_URL=""
  DRY_RUN=0
  YES=0
  NO_REBOOT=0
  LOG_FILE=""
  REPORT_FILE=""
  LOGIN_SHELL_MODE="auto"
  ONLY_SECTIONS=""
  SKIP_SECTIONS=""
  CACHE_DIR="${NIGHTWIRE_CACHE_DIR:-}"
  REMOTE_INSTALLERS=1

  # Console presentation (populated by ctf_init_colors once color is decided).
  CTF_COLOR=0
  CTF_SECTION_NUM=0
  CTF_SECTION_TOTAL=0
  C_RESET=""
  C_BOLD=""
  C_DIM=""
  C_BLUE=""
  C_CYAN=""
  C_GREEN=""
  C_YELLOW=""
  C_RED=""
  C_GREY=""
  C_MAGENTA=""

  SCRIPT_ROOT="${SCRIPT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
  MANIFEST_FILE="$SCRIPT_ROOT/manifests/tools.jsonl"
  ASSET_SOURCE_DIR="$SCRIPT_ROOT/assets"
  ASSET_INSTALL_DIR="/usr/local/share/nightwire"
  APT_UPDATED=0
  APT_FRONTEND="DEBIAN_FRONTEND=noninteractive"

  # Pinned third-party download versions (auditable; override via env).
  NERD_FONT_NAME="${NERD_FONT_NAME:-Hack}"
  NERD_FONT_VERSION="${NERD_FONT_VERSION:-v3.2.1}"
  NERD_FONT_SHA256="${NERD_FONT_SHA256:-}"

  TARGET_USER=""
  TARGET_HOME=""
  SUDO_CMD=()
  DISTRO_ID=""
  DISTRO_ID_LIKE=""
  DISTRO_VERSION=""
  DISTRO_NAME=""
  DISTRO_FAMILY=""
  DETECTED_DESKTOP="none"
  SELECTED_DESKTOP="none"
  GUI_PRESENT=0
  VM_TYPE="unknown"
  DOCKER_GROUP_CHANGED=0
  LOGIN_SHELL_CHANGED=0
  MISE_INSTALLED=0
  DESKTOP_SWITCHED=0

  PROFILE_PACKAGES=()
  SKIPPED_PACKAGES=()
  INSTALLED_PACKAGE_GROUPS=()
  PIPX_TOOLS=()
  CARGO_TOOLS=()
  GO_TOOLS=()
  GEM_TOOLS=()
  INSTALLED_PIPX_TOOLS=()
  SKIPPED_PIPX_TOOLS=()
  INSTALLED_CARGO_TOOLS=()
  SKIPPED_CARGO_TOOLS=()
  INSTALLED_GO_TOOLS=()
  SKIPPED_GO_TOOLS=()
  INSTALLED_GEM_TOOLS=()
  SKIPPED_GEM_TOOLS=()
  VALIDATION_WARNINGS=()
  ACTION_WARNINGS=()
}

ctf_require_bash() {
  if ((BASH_VERSINFO[0] < 4)); then
    printf 'This installer requires Bash 4 or newer.\n' >&2
    exit 1
  fi
}
