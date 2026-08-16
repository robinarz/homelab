# Download the Talos Image Factory ISO onto the Proxmox node (API, no SSH).
resource "proxmox_download_file" "talos_iso" {
  content_type = "iso"
  datastore_id = var.iso_datastore
  node_name    = var.pve_node
  url          = var.talos_iso_url
  file_name    = "talos-${var.talos_version}-metal-amd64.iso"
  overwrite    = false
}

# Three identical control-plane + worker nodes (HA, all schedulable).
resource "proxmox_virtual_environment_vm" "talos" {
  for_each = var.nodes

  name      = each.key
  node_name = var.pve_node
  vm_id     = each.value.vm_id
  tags      = ["talos", "kubernetes"]

  # Talos ships the qemu-guest-agent extension (see talconfig.yaml).
  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores = var.vcpus
    type  = "host" # single node, no live-migration constraints
  }

  memory {
    dedicated = var.memory_mb
  }

  # scsi0 => /dev/sda inside the VM, matching installDisk in talconfig.yaml.
  disk {
    datastore_id = var.vm_datastore
    interface    = "scsi0"
    size         = var.disk_size_gb
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  cdrom {
    file_id   = proxmox_download_file.talos_iso.id
    interface = "ide3"
  }

  network_device {
    bridge      = var.network_bridge
    model       = "virtio" # matches deviceSelector driver: virtio_net
    mac_address = each.value.mac_address
  }

  # Boot from disk once installed; fall through to the ISO on the first boot.
  boot_order = ["scsi0", "ide3"]

  # Talos writes the config to disk; ignore agent-driven IP churn on re-plans.
  lifecycle {
    ignore_changes = [network_device[0].mac_address]
  }
}
