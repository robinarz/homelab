# 1) Download + decompress the Talos disk image (nocloud, zst) onto the node.
#    Compressed downloads must be consumed via disk.file_id (not import_from).
resource "proxmox_download_file" "talos_image" {
  content_type            = "iso"
  datastore_id            = var.iso_datastore
  node_name               = var.pve_node
  url                     = var.talos_image_url
  file_name               = "talos-${var.talos_version}-nocloud-amd64.img"
  decompression_algorithm = "zst"
  overwrite               = false
}

# 2) A single Talos template. Nodes are cloned from this — sizing/agent/disk
#    are defined once here and inherited by every clone.
resource "proxmox_virtual_environment_vm" "talos_template" {
  name        = "talos-template"
  description = "Talos ${var.talos_version} — clone k8s nodes from this"
  node_name   = var.pve_node
  vm_id       = var.template_vm_id
  template    = true
  started     = false
  tags        = ["talos", "template"]

  agent { enabled = true } # Talos ships the qemu-guest-agent extension
  operating_system { type = "l26" }

  cpu {
    cores = var.vcpus
    type  = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  # scsi0 => /dev/sda inside the VM, matching installDisk in talconfig.yaml.
  disk {
    datastore_id = var.vm_datastore
    interface    = "scsi0"
    file_id      = proxmox_download_file.talos_image.id
    size         = var.disk_size_gb
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio" # matches deviceSelector driver: virtio_net
  }

  boot_order = ["scsi0"]
}

# 3) Clone the three control-plane + worker nodes from the template.
resource "proxmox_virtual_environment_vm" "talos" {
  for_each = var.nodes

  name      = each.key
  node_name = var.pve_node
  vm_id     = each.value.vm_id
  tags      = ["talos", "kubernetes"]

  clone {
    vm_id = proxmox_virtual_environment_vm.talos_template.vm_id
    full  = true
  }

  agent { enabled = true }

  # A distinct NIC per node (mac optional, e.g. for DHCP reservations).
  network_device {
    bridge      = var.network_bridge
    model       = "virtio"
    mac_address = each.value.mac_address
  }

  # cpu / memory / disk are inherited from the template.
}
