#!/usr/bin/env bash

ctf_setup_vmware() {
  local package="open-vm-tools"
  if ((GUI_PRESENT)) || [[ "$SELECTED_DESKTOP" != "none" ]]; then
    package="open-vm-tools-desktop"
  fi

  if [[ "$VM_TYPE" != "vmware" && "$VM_TYPE" != "unknown" ]]; then
    ctf_warn "Virtualization is '$VM_TYPE', not VMware. Installing VMware guest tools is skipped."
    return 0
  fi

  ctf_info "Installing VMware guest integration package: $package"
  ctf_install_packages "$package"
  ctf_enable_service_if_present vmtoolsd

  if command -v vmware-toolbox-cmd >/dev/null 2>&1; then
    ctf_try_root vmware-toolbox-cmd timesync enable
  fi
}
