#!/usr/bin/env bash

ctf_install_command_framework() {
  ctf_info "Installing nightwire command framework."
  if ((${#PROFILE_PACKAGES[@]} == 0)) && [[ -n "$PROFILE" ]]; then
    ctf_resolve_profile_packages "$PROFILE"
  fi
  ctf_run_root install -d -m 0755 "$ASSET_INSTALL_DIR"
  ctf_run_root install -d -m 0755 "$ASSET_INSTALL_DIR/tool-lists" "$ASSET_INSTALL_DIR/templates" "$ASSET_INSTALL_DIR/labs" "$ASSET_INSTALL_DIR/browser" "$ASSET_INSTALL_DIR/manifests" "$ASSET_INSTALL_DIR/examples" "$ASSET_INSTALL_DIR/debuggers" "$ASSET_INSTALL_DIR/assets"

  if [[ -f "$SCRIPT_ROOT/bin/nightwire" ]]; then
    ctf_run_root install -D -m 0755 "$SCRIPT_ROOT/bin/nightwire" /usr/local/bin/nightwire
  else
    ctf_warn "Missing bin/nightwire; command framework was not installed."
  fi

  # Stage the installer itself so `nightwire reconfigure` can refresh managed
  # shell/desktop config from the version that is on the box.
  if [[ -f "$SCRIPT_ROOT/install.sh" && -d "$SCRIPT_ROOT/lib" ]]; then
    ctf_run_root install -d -m 0755 "$ASSET_INSTALL_DIR/installer" "$ASSET_INSTALL_DIR/installer/lib"
    ctf_run_root install -D -m 0755 "$SCRIPT_ROOT/install.sh" "$ASSET_INSTALL_DIR/installer/install.sh"
    ctf_install_resource_dir "$SCRIPT_ROOT/lib" "$ASSET_INSTALL_DIR/installer/lib"
  fi

  ctf_install_resource_dir "$SCRIPT_ROOT/assets" "$ASSET_INSTALL_DIR/assets"
  ctf_install_resource_dir "$SCRIPT_ROOT/templates" "$ASSET_INSTALL_DIR/templates"
  ctf_install_resource_dir "$SCRIPT_ROOT/labs" "$ASSET_INSTALL_DIR/labs"
  ctf_install_resource_dir "$SCRIPT_ROOT/browser" "$ASSET_INSTALL_DIR/browser"
  ctf_install_resource_dir "$SCRIPT_ROOT/manifests" "$ASSET_INSTALL_DIR/manifests"
  ctf_install_resource_dir "$SCRIPT_ROOT/examples" "$ASSET_INSTALL_DIR/examples"
  ctf_install_resource_dir "$SCRIPT_ROOT/debuggers" "$ASSET_INSTALL_DIR/debuggers"
  if [[ -f "$ASSET_INSTALL_DIR/debuggers/install-debuggers.sh" ]]; then
    ctf_run_root chmod 0755 "$ASSET_INSTALL_DIR/debuggers/install-debuggers.sh"
  fi
  ctf_write_tool_lists
}

ctf_install_resource_dir() {
  local source_dir="$1"
  local target_dir="$2"

  if [[ ! -d "$source_dir" ]]; then
    ctf_warn "Resource directory missing: $source_dir"
    return 0
  fi

  ctf_run_root cp -a "$source_dir/." "$target_dir/"
}

ctf_write_tool_lists() {
  local go_lines cargo_lines pipx_lines gem_lines
  go_lines="$(printf '%s\n' "${GO_TOOLS[@]}")"
  cargo_lines="$(printf '%s\n' "${CARGO_TOOLS[@]}")"
  pipx_lines="$(printf '%s\n' "${PIPX_TOOLS[@]}")"
  gem_lines="$(printf '%s\n' "${GEM_TOOLS[@]}")"

  ctf_write_root_file "$ASSET_INSTALL_DIR/tool-lists/go-tools.txt" "$go_lines" 0644 root:root
  ctf_write_root_file "$ASSET_INSTALL_DIR/tool-lists/cargo-tools.txt" "$cargo_lines" 0644 root:root
  ctf_write_root_file "$ASSET_INSTALL_DIR/tool-lists/pipx-tools.txt" "$pipx_lines" 0644 root:root
  ctf_write_root_file "$ASSET_INSTALL_DIR/tool-lists/gem-tools.txt" "$gem_lines" 0644 root:root
  ctf_write_root_file "$ASSET_INSTALL_DIR/workspace-root" "$WORKSPACE_DIR" 0644 root:root
}
