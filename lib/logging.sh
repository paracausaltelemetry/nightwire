#!/usr/bin/env bash

ctf_init_colors() {
  if ((CTF_COLOR)); then
    C_RESET=$'\e[0m'
    C_BOLD=$'\e[1m'
    C_DIM=$'\e[2m'
    C_BLUE=$'\e[38;5;39m'
    C_CYAN=$'\e[38;5;44m'
    C_GREEN=$'\e[38;5;78m'
    C_YELLOW=$'\e[38;5;220m'
    C_RED=$'\e[38;5;203m'
    C_GREY=$'\e[38;5;245m'
    C_MAGENTA=$'\e[38;5;176m'
  else
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
  fi
}

ctf_setup_logging() {
  if [[ -z "$LOG_FILE" ]]; then
    LOG_FILE="${TMPDIR:-/tmp}/nightwire-$(date +%Y%m%d-%H%M%S).log"
  fi

  local log_dir
  log_dir="$(dirname "$LOG_FILE")"
  if ! mkdir -p "$log_dir" 2>/dev/null || ! touch "$LOG_FILE" 2>/dev/null; then
    LOG_FILE="${TMPDIR:-/tmp}/nightwire-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
  fi

  # Decide on color from the real stdout before it is redirected to the tee.
  if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-dumb}" != "dumb" ]]; then
    CTF_COLOR=1
  else
    CTF_COLOR=0
  fi
  ctf_init_colors

  # Mirror everything to the terminal (colored) and an ANSI-stripped copy to the
  # log file, so the log stays clean and greppable.
  if command -v sed >/dev/null 2>&1; then
    exec > >(tee >(sed -u 's/\x1b\[[0-9;]*m//g' >>"$LOG_FILE")) 2>&1
  else
    exec > >(tee -a "$LOG_FILE") 2>&1
  fi
}

ctf_banner() {
  printf '%s' "${C_CYAN}${C_BOLD}"
  cat <<'BANNER'
   ______ ______ ______   _    ____  ___
  / ____//_  __// ____/  | |  / /  |/  /
 / /      / /  / /_____  | | / / /|_/ /
/ /___   / /  / ____/ /  | |/ / /  / /
\____/  /_/  /_/   /_/   |___/_/  /_/
BANNER
  printf '%s%sNightwire Bootstrap%s\n\n' "$C_RESET" "$C_BOLD" "$C_RESET"
  ctf_info "Version: $NIGHTWIRE_VERSION"
  ctf_info "Log file: $LOG_FILE"
}

ctf_timestamp() {
  date '+%H:%M:%S'
}

# A bold section header with an inline progress bar, e.g.
# "▶ Packages & tools  [████████░░░░░░░░] 2/11".
ctf_section() {
  local title="$1"
  local bar=""
  if ((CTF_SECTION_TOTAL > 0)); then
    local width=16 filled i
    filled=$((CTF_SECTION_NUM * width / CTF_SECTION_TOTAL))
    bar="["
    for ((i = 0; i < width; i++)); do
      if ((i < filled)); then bar+="█"; else bar+="░"; fi
    done
    bar+="] $CTF_SECTION_NUM/$CTF_SECTION_TOTAL"
  fi
  printf '\n%s%s▶ %s%s  %s%s%s\n' "$C_BOLD" "$C_CYAN" "$title" "$C_RESET" "$C_DIM" "$bar" "$C_RESET"
}

# Dim, indented echo of the commands being executed (recedes behind real status).
ctf_trace() {
  printf '%s  ↳ %s%s\n' "$C_DIM" "$*" "$C_RESET"
}

ctf_log() {
  local level="$1"
  shift
  local sym color
  case "$level" in
    OK) sym="✓" color="$C_GREEN" ;;
    WARN) sym="⚠" color="$C_YELLOW" ;;
    ERROR) sym="✗" color="$C_RED" ;;
    *) sym="•" color="$C_BLUE" ;;
  esac
  printf '%s%s%s %s%s%s %s\n' "$C_DIM" "$(ctf_timestamp)" "$C_RESET" "$color" "$sym" "$C_RESET" "$*"
}

ctf_info() {
  ctf_log INFO "$@"
}

ctf_warn() {
  ctf_log WARN "$@"
  ACTION_WARNINGS+=("$*")
}

ctf_error() {
  ctf_log ERROR "$@"
}

ctf_success() {
  ctf_log OK "$@"
}

ctf_die() {
  ctf_error "$@"
  exit 1
}

ctf_run() {
  ctf_trace "$*"
  if ((DRY_RUN)); then
    return 0
  fi
  "$@"
}

ctf_run_root() {
  if ((${#SUDO_CMD[@]})); then
    ctf_run "${SUDO_CMD[@]}" "$@"
  else
    ctf_run "$@"
  fi
}

ctf_try_root() {
  ctf_trace "$*"
  if ((DRY_RUN)); then
    return 0
  fi
  if ((${#SUDO_CMD[@]})); then
    "${SUDO_CMD[@]}" "$@" || ctf_warn "Command failed but bootstrap will continue: $*"
  else
    "$@" || ctf_warn "Command failed but bootstrap will continue: $*"
  fi
}

ctf_run_user_shell() {
  local command="$1"
  local user_path="$TARGET_HOME/.local/bin:$TARGET_HOME/.cargo/bin:$TARGET_HOME/go/bin:$PATH"
  ctf_trace "user:$TARGET_USER $command"
  if ((DRY_RUN)); then
    return 0
  fi

  if [[ "$(id -un)" == "$TARGET_USER" ]]; then
    HOME="$TARGET_HOME" PATH="$user_path" bash -lc "$command"
  elif command -v sudo >/dev/null 2>&1; then
    sudo -H -u "$TARGET_USER" env HOME="$TARGET_HOME" PATH="$user_path" bash -lc "$command"
  else
    ctf_die "Cannot run user command for $TARGET_USER because sudo is unavailable."
  fi
}

ctf_try_user_shell() {
  local command="$1"
  local user_path="$TARGET_HOME/.local/bin:$TARGET_HOME/.cargo/bin:$TARGET_HOME/go/bin:$PATH"
  ctf_trace "user:$TARGET_USER $command"
  if ((DRY_RUN)); then
    return 0
  fi

  if [[ "$(id -un)" == "$TARGET_USER" ]]; then
    HOME="$TARGET_HOME" PATH="$user_path" bash -lc "$command" || ctf_warn "User command failed but bootstrap will continue: $command"
  elif command -v sudo >/dev/null 2>&1; then
    sudo -H -u "$TARGET_USER" env HOME="$TARGET_HOME" PATH="$user_path" bash -lc "$command" || ctf_warn "User command failed but bootstrap will continue: $command"
  else
    ctf_warn "Cannot run user command for $TARGET_USER because sudo is unavailable."
  fi
}

ctf_backup_file_once() {
  local path="$1"
  if [[ -e "$path" && ! -e "$path.nightwire.bak" ]]; then
    ctf_run_root cp -a "$path" "$path.nightwire.bak"
  fi
}

ctf_write_root_file() {
  local path="$1"
  local content="$2"
  local mode="${3:-0644}"
  local owner="${4:-root:root}"
  local tmp
  tmp="$(mktemp)"
  printf '%s\n' "$content" >"$tmp"
  ctf_run_root install -D -m "$mode" -o "${owner%%:*}" -g "${owner##*:}" "$tmp" "$path"
  rm -f "$tmp"
}

# Insert or refresh a Nightwire-managed block in a file. The start marker carries
# a content hash, so re-running the installer updates the block in place when its
# content changed, and is a no-op when it did not. Any non-managed content in the
# file is preserved.
ctf_append_marker_block_root() {
  local path="$1"
  local marker="$2"
  local content="$3"
  local owner="${4:-root:root}"
  local start_prefix="# >>> nightwire: $marker "
  local end="# <<< nightwire: $marker <<<"
  local hash
  hash="$(printf '%s' "$content" | cksum | awk '{print $1}')"
  local start="${start_prefix}[v$hash] >>>"

  if [[ -f "$path" ]] && grep -Fq "$start" "$path"; then
    ctf_info "Up to date: $path ($marker)"
    return 0
  fi

  ctf_backup_file_once "$path"

  local existing=""
  if [[ -f "$path" ]]; then
    if grep -Fq "$start_prefix" "$path"; then
      ctf_info "Refreshing managed block: $path ($marker)"
    fi
    existing="$(ctf_strip_marker_block "$path" "$start_prefix" "$end")"
  fi

  local payload
  if [[ -n "$existing" ]]; then
    payload="$existing"$'\n\n'"$start"$'\n'"$content"$'\n'"$end"
  else
    payload="$start"$'\n'"$content"$'\n'"$end"
  fi

  ctf_write_root_file "$path" "$payload" 0644 "$owner"
}

# Print a file's contents with the named Nightwire block removed (inclusive of
# its start and end markers). $() trims the trailing newlines for clean reassembly.
ctf_strip_marker_block() {
  local path="$1"
  local start_prefix="$2"
  local end="$3"
  awk -v sp="$start_prefix" -v e="$end" '
    index($0, sp) == 1 { skip = 1 }
    skip && $0 == e { skip = 0; next }
    skip { next }
    { print }
  ' "$path"
}
