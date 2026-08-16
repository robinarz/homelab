# ---- Proxmox connection ----
variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API endpoint, e.g. https://192.168.1.5:8006/"
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "API token: tofu@pve!automation=<uuid>. Prefer TF_VAR_proxmox_api_token env var."
}

variable "proxmox_insecure" {
  type        = bool
  default     = true # self-signed PVE certificate
  description = "Skip TLS verification for the Proxmox API."
}

variable "pve_node" {
  type        = string
  description = "Proxmox node name (as shown in the UI), e.g. proxmox"
}

# ---- Datastores / network ----
variable "iso_datastore" {
  type        = string
  default     = "local"
  description = "Datastore that holds ISO images."
}

variable "vm_datastore" {
  type        = string
  description = "Datastore for VM system disks, e.g. local-zfs or local-lvm."
}

variable "network_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Linux bridge the VMs attach to."
}

# ---- Talos image ----
variable "talos_version" {
  type        = string
  default     = "v1.13.8" # keep in sync with talos/talenv.yaml
  description = "Talos version (used only in the ISO filename)."
}

variable "talos_image_url" {
  type        = string
  description = "Image Factory disk image from `task talos:schematic` (nocloud-amd64.raw.zst)."
}

variable "template_vm_id" {
  type        = number
  default     = 8100
  description = "VMID of the Talos template that the nodes are cloned from."
}

# ---- VM sizing (matches the topology: 4 vCPU / 8GB each) ----
variable "vcpus" {
  type    = number
  default = 4
}

variable "memory_mb" {
  type    = number
  default = 8192
}

variable "disk_size_gb" {
  type        = number
  default     = 100 # OS + local-path config PVCs (Plex metadata, *arr DBs)
  description = "System disk size per node in GB."
}

# ---- Nodes ----
variable "nodes" {
  type = map(object({
    vm_id       = number
    mac_address = optional(string) # optional: set for stable DHCP reservations
  }))
  default = {
    talos-01 = { vm_id = 8101 }
    talos-02 = { vm_id = 8102 }
    talos-03 = { vm_id = 8103 }
  }
  description = "Talos VMs to create (hostnames should match talos/talconfig.yaml)."
}
