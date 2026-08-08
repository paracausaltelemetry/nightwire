#!/usr/bin/env bash

ctf_validate_install() {
  ctf_info "Running post-install validation."
  ctf_validate_commands git curl python3 tmux nmap nightwire

  if [[ "$PROFILE" == "standard" || "$PROFILE" == "full" ]]; then
    ctf_validate_commands sqlmap john hashcat binwalk feroxbuster rustscan
  fi

  if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files vmtoolsd.service >/dev/null 2>&1; then
    if ! systemctl is-active --quiet vmtoolsd; then
      VALIDATION_WARNINGS+=("vmtoolsd service is installed but not active.")
    fi
  fi

  if ((DOCKER_GROUP_CHANGED)); then
    VALIDATION_WARNINGS+=("$TARGET_USER was added to the docker group; log out and back in before using Docker without sudo.")
  fi

  if ((LOGIN_SHELL_CHANGED)); then
    VALIDATION_WARNINGS+=("Login shell was changed; start a new login session to use it.")
  fi

  if ((DESKTOP_SWITCHED)); then
    VALIDATION_WARNINGS+=("Desktop switched to GNOME with GDM3; reboot to land in the GNOME session.")
  fi

  if ctf_section_enabled shell; then
    if [[ "$SHELL_MODE" == "zsh" || "$SHELL_MODE" == "both" ]]; then
      if [[ ! -e /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh && ! -d "$TARGET_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
        VALIDATION_WARNINGS+=("Zsh autosuggestions plugin not found; shell autocomplete will be limited.")
      fi
    fi
    if [[ "$SHELL_MODE" == "bash" || "$SHELL_MODE" == "both" ]]; then
      if [[ ! -f "$TARGET_HOME/.local/share/blesh/ble.sh" ]]; then
        VALIDATION_WARNINGS+=("ble.sh not found; Bash will use readline completion without inline autosuggestions.")
      fi
    fi
  fi

  if [[ "$RUNTIME_MODE" == "mise" ]] && ! ctf_user_mise_available; then
    VALIDATION_WARNINGS+=("mise runtime manager was requested but is not available for $TARGET_USER.")
  fi

  [[ -d "$WORKSPACE_DIR" ]] || VALIDATION_WARNINGS+=("Workspace directory missing: $WORKSPACE_DIR")
  [[ -f "$ASSET_INSTALL_DIR/labs/docker-compose.yml" || "$LAB_MODE" == "none" ]] || VALIDATION_WARNINGS+=("Local lab compose file missing.")
  [[ -f "$ASSET_INSTALL_DIR/browser/firefox-proxy-user.js" || "$BROWSER_MODE" == "none" ]] || VALIDATION_WARNINGS+=("Browser proxy helper missing.")
}

ctf_validate_commands() {
  local command_name
  for command_name in "$@"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      VALIDATION_WARNINGS+=("Command not found after install: $command_name")
    fi
  done
}

ctf_join_lines() {
  local item
  for item in "$@"; do
    printf -- '- %s\n' "$item"
  done
}

ctf_write_report() {
  REPORT_FILE="$ASSET_INSTALL_DIR/install-report.txt"
  local remote_label="disabled"
  ((REMOTE_INSTALLERS)) && remote_label="enabled"
  local report
  report="$(
    cat <<EOF
Nightwire Bootstrap Report
Generated: $(date -Is)
Version: $NIGHTWIRE_VERSION

System
- Distro: $DISTRO_NAME
- Family: $DISTRO_FAMILY
- Desktop: $SELECTED_DESKTOP
- Virtualization: $VM_TYPE
- Target user: $TARGET_USER

Selections
- Profile: $PROFILE
- Extra profiles: ${EXTRA_PROFILES:-none}
- Shell mode: $SHELL_MODE
- Runtime mode: $RUNTIME_MODE
- Browser mode: $BROWSER_MODE
- Lab mode: $LAB_MODE
- Workspace: $WORKSPACE_DIR
- Assets URL: ${ASSETS_URL:-bundled assets}
- Cache dir: ${CACHE_DIR:-none}
- Remote installers: $remote_label
- Dry run: $DRY_RUN
- Only sections: ${ONLY_SECTIONS:-all}
- Skipped sections: ${SKIP_SECTIONS:-none}

Skipped apt packages
$(if ((${#SKIPPED_PACKAGES[@]})); then ctf_join_lines "${SKIPPED_PACKAGES[@]}"; else printf -- '- none\n'; fi)

Installed pipx tools
$(if ((${#INSTALLED_PIPX_TOOLS[@]})); then ctf_join_lines "${INSTALLED_PIPX_TOOLS[@]}"; else printf -- '- none or skipped\n'; fi)

Skipped pipx tools
$(if ((${#SKIPPED_PIPX_TOOLS[@]})); then ctf_join_lines "${SKIPPED_PIPX_TOOLS[@]}"; else printf -- '- none\n'; fi)

Installed Cargo tools
$(if ((${#INSTALLED_CARGO_TOOLS[@]})); then ctf_join_lines "${INSTALLED_CARGO_TOOLS[@]}"; else printf -- '- none or already present\n'; fi)

Skipped Cargo tools
$(if ((${#SKIPPED_CARGO_TOOLS[@]})); then ctf_join_lines "${SKIPPED_CARGO_TOOLS[@]}"; else printf -- '- none\n'; fi)

Installed Go tools
$(if ((${#INSTALLED_GO_TOOLS[@]})); then ctf_join_lines "${INSTALLED_GO_TOOLS[@]}"; else printf -- '- none or already present\n'; fi)

Skipped Go tools
$(if ((${#SKIPPED_GO_TOOLS[@]})); then ctf_join_lines "${SKIPPED_GO_TOOLS[@]}"; else printf -- '- none\n'; fi)

Installed Ruby gems
$(if ((${#INSTALLED_GEM_TOOLS[@]})); then ctf_join_lines "${INSTALLED_GEM_TOOLS[@]}"; else printf -- '- none or already present\n'; fi)

Skipped Ruby gems
$(if ((${#SKIPPED_GEM_TOOLS[@]})); then ctf_join_lines "${SKIPPED_GEM_TOOLS[@]}"; else printf -- '- none\n'; fi)

Warnings
$(if ((${#ACTION_WARNINGS[@]})); then ctf_join_lines "${ACTION_WARNINGS[@]}"; else printf -- '- none\n'; fi)

Validation warnings
$(if ((${#VALIDATION_WARNINGS[@]})); then ctf_join_lines "${VALIDATION_WARNINGS[@]}"; else printf -- '- none\n'; fi)

Next steps
- Open a new terminal to load shell changes.
- Log out and back in if Docker group membership or login shell changed.
- Log out and back in for the GNOME Shell theme/extension to take effect (Wayland cannot reload the shell live).
- If desktop settings did not apply, run the installer from inside the graphical session.
EOF
  )"

  ctf_write_root_file "$REPORT_FILE" "$report" 0644 root:root
  if ! ((NO_REBOOT)); then
    ctf_info "A reboot is recommended after VMware tools, kernel-adjacent tools, or shell/group changes."
  fi
}
