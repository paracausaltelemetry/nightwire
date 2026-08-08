#!/usr/bin/env bash

ctf_setup_browser_helpers() {
  case "$BROWSER_MODE" in
    none)
      ctf_info "Browser/proxy helper setup skipped."
      return 0
      ;;
    basic | proxy)
      ctf_info "Installing browser/proxy helper assets."
      ;;
  esac

  ctf_install_packages firefox-esr chromium zaproxy
  ctf_run_root install -d -m 0755 "$ASSET_INSTALL_DIR/browser"
  ctf_install_resource_dir "$SCRIPT_ROOT/browser" "$ASSET_INSTALL_DIR/browser"

  if [[ "$BROWSER_MODE" == "proxy" ]]; then
    ctf_try_user_shell "if command -v nightwire >/dev/null 2>&1; then nightwire browser-proxy nightwire-proxy || true; fi"
  fi
}
