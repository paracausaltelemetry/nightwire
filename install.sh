#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/config.sh
source "$SCRIPT_DIR/lib/config.sh"
# shellcheck source=lib/logging.sh
source "$SCRIPT_DIR/lib/logging.sh"
# shellcheck source=lib/args.sh
source "$SCRIPT_DIR/lib/args.sh"
# shellcheck source=lib/tui.sh
source "$SCRIPT_DIR/lib/tui.sh"
# shellcheck source=lib/detect.sh
source "$SCRIPT_DIR/lib/detect.sh"
# shellcheck source=lib/apt.sh
source "$SCRIPT_DIR/lib/apt.sh"
# shellcheck source=lib/runtime.sh
source "$SCRIPT_DIR/lib/runtime.sh"
# shellcheck source=lib/packages.sh
source "$SCRIPT_DIR/lib/packages.sh"
# shellcheck source=lib/assets.sh
source "$SCRIPT_DIR/lib/assets.sh"
# shellcheck source=lib/command.sh
source "$SCRIPT_DIR/lib/command.sh"
# shellcheck source=lib/workspace.sh
source "$SCRIPT_DIR/lib/workspace.sh"
# shellcheck source=lib/browser.sh
source "$SCRIPT_DIR/lib/browser.sh"
# shellcheck source=lib/labs.sh
source "$SCRIPT_DIR/lib/labs.sh"
# shellcheck source=lib/vmware.sh
source "$SCRIPT_DIR/lib/vmware.sh"
# shellcheck source=lib/shell.sh
source "$SCRIPT_DIR/lib/shell.sh"
# shellcheck source=lib/desktop.sh
source "$SCRIPT_DIR/lib/desktop.sh"
# shellcheck source=lib/validate.sh
source "$SCRIPT_DIR/lib/validate.sh"

main() {
  ctf_init_defaults
  ctf_parse_args "$@"
  ctf_tui_configure
  ctf_setup_logging
  trap 'ctf_error "Bootstrap failed near line $LINENO. See $LOG_FILE for details."' ERR

  ctf_banner
  ctf_require_bash
  ctf_detect_platform
  ctf_prepare_privilege
  ctf_resolve_target_user
  ctf_interactive_defaults
  ctf_validate_options
  ctf_confirm_scope
  ctf_preflight_checks

  ctf_count_sections
  ctf_run_section runtime "Runtime managers" ctf_setup_runtime
  ctf_run_section packages "Packages & tools" ctf_install_profile
  ctf_run_section assets "Assets" ctf_setup_assets
  ctf_run_section command "nightwire command" ctf_install_command_framework
  ctf_run_section workspace "Workspace" ctf_setup_workspace
  ctf_run_section browser "Browser helpers" ctf_setup_browser_helpers
  ctf_run_section labs "Local labs" ctf_setup_labs
  ctf_run_section vmware "VMware integration" ctf_setup_vmware
  ctf_run_section shell "Shell & autocomplete" ctf_setup_shells
  ctf_run_section desktop "Desktop / UI" ctf_setup_desktop
  ctf_run_section validate "Validation" ctf_validate_install
  ctf_write_report

  ctf_success "Nightwire bootstrap complete. Review the report at $REPORT_FILE"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
