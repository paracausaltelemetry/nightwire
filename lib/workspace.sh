#!/usr/bin/env bash

ctf_setup_workspace() {
  ctf_info "Creating CTF workspace at $WORKSPACE_DIR"
  local owner="$TARGET_USER:$(id -gn "$TARGET_USER")"
  ctf_run_root install -d -m 0755 -o "$TARGET_USER" -g "$(id -gn "$TARGET_USER")" "$WORKSPACE_DIR"
  ctf_run_root install -d -m 0755 -o "$TARGET_USER" -g "$(id -gn "$TARGET_USER")" \
    "$WORKSPACE_DIR/_templates" \
    "$WORKSPACE_DIR/_shared" \
    "$WORKSPACE_DIR/_wordlists" \
    "$WORKSPACE_DIR/_payloads"

  if [[ -d "$SCRIPT_ROOT/templates/workspace" ]]; then
    ctf_run_root cp -an "$SCRIPT_ROOT/templates/workspace/." "$WORKSPACE_DIR/_templates/"
    ctf_run_root chown -R "$owner" "$WORKSPACE_DIR/_templates"
  fi
}
