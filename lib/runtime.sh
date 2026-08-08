#!/usr/bin/env bash

ctf_setup_runtime() {
  case "$RUNTIME_MODE" in
    none)
      ctf_info "Runtime manager setup skipped."
      ;;
    system)
      ctf_info "Using distro-provided runtimes from apt packages."
      ;;
    mise)
      ctf_install_mise
      ;;
  esac
}

ctf_install_mise() {
  if ctf_user_mise_available; then
    ctf_info "mise is already available for $TARGET_USER."
    return 0
  fi

  if ! ((REMOTE_INSTALLERS)); then
    ctf_warn "mise runtime requested but remote installers are disabled; skipping. Use --runtime system."
    return 0
  fi

  ctf_install_packages curl ca-certificates git
  ctf_warn "Installing mise with its official bootstrap script for user-level runtime management."
  ctf_run_user_shell "curl -fsSL https://mise.run | sh"
  MISE_INSTALLED=1

  ctf_try_user_shell "mkdir -p \"\$HOME/.config/mise\""
  ctf_try_user_shell "mise settings set experimental true || true"
  ctf_try_user_shell "mise use -g go@latest rust@stable node@lts ruby@latest || true"
}

ctf_user_mise_available() {
  local check="command -v mise >/dev/null 2>&1 || [ -x \"\$HOME/.local/bin/mise\" ]"
  if [[ "$(id -un)" == "$TARGET_USER" ]]; then
    HOME="$TARGET_HOME" PATH="$TARGET_HOME/.local/bin:$PATH" bash -lc "$check"
  elif command -v sudo >/dev/null 2>&1; then
    sudo -H -u "$TARGET_USER" env HOME="$TARGET_HOME" PATH="$TARGET_HOME/.local/bin:$PATH" bash -lc "$check"
  else
    return 1
  fi
}
