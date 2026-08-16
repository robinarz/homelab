output "vms" {
  description = "Created Talos VMs (name => id)."
  value       = { for k, v in proxmox_virtual_environment_vm.talos : k => v.vm_id }
}

output "talos_iso" {
  description = "ISO file id downloaded to Proxmox."
  value       = proxmox_download_file.talos_iso.id
}
