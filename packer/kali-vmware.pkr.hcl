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
  description = "Kali ISO URL or local path."
}

variable "iso_checksum" {
  type        = string
  description = "ISO checksum, for example sha256:<hash>."
}

variable "vm_name" {
  type    = string
  default = "nightwire-kali"
}

variable "ssh_username" {
  type    = string
  default = "kali"
}

variable "ssh_password" {
  type      = string
  default   = "kali"
  sensitive = true
}

variable "repo_url" {
  type        = string
  default     = "https://github.com/paracausaltelemetry/nightwire.git"
  description = "Repository URL for this bootstrap project."
}

source "vmware-iso" "ctf" {
  vm_name          = var.vm_name
  guest_os_type    = "debian12-64"
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_timeout      = "45m"
  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  disk_size        = 81920
  memory           = 8192
  cpus             = 4
  headless         = false
}

build {
  sources = ["source.vmware-iso.ctf"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y git curl ca-certificates",
      "git clone ${var.repo_url} /tmp/nightwire",
      "cd /tmp/nightwire && sudo ./install.sh --profile full --extras all --runtime mise --yes --no-reboot"
    ]
  }
}
