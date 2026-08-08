#!/usr/bin/env bash

ctf_setup_labs() {
  case "$LAB_MODE" in
    none)
      ctf_info "Local Docker lab asset setup skipped."
      return 0
      ;;
    local | all)
      ctf_info "Installing local-only vulnerable lab compose assets."
      ;;
  esac

  ctf_install_packages docker.io docker-compose
  ctf_run_root install -d -m 0755 "$ASSET_INSTALL_DIR/labs"
  ctf_install_resource_dir "$SCRIPT_ROOT/labs" "$ASSET_INSTALL_DIR/labs"
}
