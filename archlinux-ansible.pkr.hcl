packer {
  required_plugins {
    vagrant = {
      version = "~> 1"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

# --- Variables ---

variable "registry_name" {
  type        = string
  default     = "marcstraube"
  description = "HCP Vagrant Registry username."
}

variable "box_name" {
  type        = string
  default     = "archlinux-ansible"
  description = "Name of the Vagrant box."
}

variable "reflector_countries" {
  type        = string
  default     = ""
  description = "Comma-separated list of countries for reflector mirror selection. Empty uses all countries."
}

variable "no_release" {
  type        = bool
  default     = true
  description = "When true, the uploaded version is not automatically released."
}

variable "hcp_client_id" {
  type        = string
  default     = env("HCP_CLIENT_ID")
  sensitive   = true
  description = "HCP Service Principal client ID. Set via HCP_CLIENT_ID environment variable."
}

variable "hcp_client_secret" {
  type        = string
  default     = env("HCP_CLIENT_SECRET")
  sensitive   = true
  description = "HCP Service Principal client secret. Set via HCP_CLIENT_SECRET environment variable."
}

# --- Locals ---

locals {
  timestamp               = timestamp()
  box_version             = formatdate("YYYYMMDD.hhmmss", local.timestamp)
  box_version_description = "Build on ${formatdate("EEEE, DD. MMMM YYYY", local.timestamp)} at ${formatdate("hh:mm:ss", local.timestamp)} UTC. This version contains all upstream package updates available at the time of the build."
  box_tag                 = "${var.registry_name}/${var.box_name}"
}

# --- Source ---

source "vagrant" "archlinux" {
  source_path  = "generic/arch"
  provider     = "virtualbox"
  communicator = "ssh"
  add_force    = true
}

# --- Build ---

build {
  sources = ["source.vagrant.archlinux"]

  provisioner "shell" {
    environment_vars = [
      "REFLECTOR_COUNTRIES=${var.reflector_countries}",
    ]
    execute_command = "chmod +x {{ .Path }}; sudo env {{ .Vars }} bash {{ .Path }}"
    inline = [
      "set -e",
      "",
      "echo '==> Initializing pacman keyring'",
      "pacman-key --init",
      "pacman-key --populate archlinux",
      "",
      "echo '==> Updating archlinux-keyring'",
      "pacman -Sy --noconfirm --needed archlinux-keyring",
      "",
      "echo '==> Performing full system upgrade'",
      "pacman -Syu --noconfirm",
      "",
      "echo '==> Installing reflector and Python'",
      "pacman -S --noconfirm --needed reflector python",
      "",
      "echo '==> Updating mirrorlist with reflector'",
      "REFLECTOR_ARGS='--protocol https --sort rate --save /etc/pacman.d/mirrorlist'",
      "if [ -n \"$REFLECTOR_COUNTRIES\" ]; then",
      "  SAVED_IFS=\"$IFS\"",
      "  IFS=','",
      "  for country in $REFLECTOR_COUNTRIES; do",
      "    country=$(echo \"$country\" | xargs)",
      "    REFLECTOR_ARGS=\"$REFLECTOR_ARGS --country $country\"",
      "  done",
      "  IFS=\"$SAVED_IFS\"",
      "  echo \"    Filtering mirrors for: $REFLECTOR_COUNTRIES\"",
      "else",
      "  echo '    Using mirrors from all countries'",
      "fi",
      "eval reflector $REFLECTOR_ARGS",
      "echo '    Mirrorlist updated successfully'",
      "",
      "echo '==> Cleaning up'",
      "find / -type f -iname '*.pacnew' -exec rm -f {} +",
      "pacman -Scc --noconfirm",
      "dd if=/dev/zero of=/EMPTY bs=1M || echo \"dd exit code $? is suppressed\"",
      "rm -f /EMPTY",
      "rm -f /home/vagrant/.bash_history",
      "history -c",
      "sync",
    ]
  }

  post-processor "vagrant-registry" {
    box_tag             = local.box_tag
    version             = local.box_version
    version_description = local.box_version_description
    architecture        = "amd64"
    no_release          = var.no_release
    client_id           = var.hcp_client_id
    client_secret       = var.hcp_client_secret
  }
}
