packer {
  required_plugins {
    vmware = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

variable "iso_url" {
  type        = string
  description = "Ubuntu/Debian ISO URL or local path."
}

variable "iso_checksum" {
  type        = string
  description = "ISO checksum, for example sha256:<hash>."
}

variable "vm_name" {
  type    = string
  default = "nightwire-ubuntu"
}

variable "ssh_username" {
  type    = string
  default = "ctf"
}

variable "ssh_password" {
  type      = string
  default   = "ctf"
  sensitive = true
}

variable "repo_url" {
  type        = string
  default     = "https://github.com/paracausaltelemetry/nightwire.git"
  description = "Repository URL for this bootstrap project."
}

variable "guest_os_type" {
  type        = string
  default     = "ubuntu-64"
  description = "VMware guest OS identifier. Use a newer one (for example debian13-64) when your VMware release lists it."
}

variable "install_args" {
  type        = string
  default     = "--config examples/nightwire.yml --yes --no-reboot"
  description = "Arguments passed to install.sh."
}

source "vmware-iso" "ctf" {
  vm_name          = var.vm_name
  guest_os_type    = var.guest_os_type
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_timeout      = "45m"
  # Passwordless sudo is granted for the build only (see the first provisioner)
  # and removed as part of shutdown, so the password never hits a command line.
  shutdown_command = "sudo sh -c 'rm -f /etc/sudoers.d/99-packer-build; shutdown -P now'"
  disk_size        = 81920
  memory           = 8192
  cpus             = 4
  headless         = false
}

build {
  sources = ["source.vmware-iso.ctf"]

  # Grant temporary passwordless sudo. The password travels in an env-var file
  # (use_env_var_file) that Packer redacts in logs, never on a command line.
  provisioner "shell" {
    use_env_var_file = true
    environment_vars = ["SUDO_PASS=${var.ssh_password}"]
    inline = [
      "echo \"$SUDO_PASS\" | sudo -S -p '' sh -c 'echo \"${var.ssh_username} ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/99-packer-build && chmod 0440 /etc/sudoers.d/99-packer-build'"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y git curl ca-certificates",
      "git clone --depth 1 ${var.repo_url} /tmp/nightwire",
      "cd /tmp/nightwire && sudo ./install.sh ${var.install_args}"
    ]
  }
}
