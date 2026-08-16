# API-token auth for everything, plus an SSH block used only for the one
# operation that needs node access: importing the Talos disk image into the
# template. SSH is as `robinho` (key from your ssh-agent) with passwordless
# sudo — root SSH stays disabled.
provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  ssh {
    agent    = true
    username = var.proxmox_ssh_username
  }
}
