# Auth via a dedicated PVE-realm API token (see README). Everything here is
# API-only, so no SSH access to the Proxmox host is required.
provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}
