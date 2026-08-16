output "vms" {
  description = "Created Talos VMs (name => id)."
  value       = { for k, v in proxmox_virtual_environment_vm.talos : k => v.vm_id }
}

output "talos_template" {
  description = "Template VMID the nodes are cloned from."
  value       = proxmox_virtual_environment_vm.talos_template.vm_id
}

output "talos_image" {
  description = "Talos disk image downloaded to Proxmox."
  value       = proxmox_download_file.talos_image.id
}
