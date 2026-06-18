output "name" {
  description = "VM name."
  value       = proxmox_virtual_environment_vm.vm.name
}

output "vm_id" {
  description = "VMID."
  value       = proxmox_virtual_environment_vm.vm.vm_id
}

output "role" {
  description = "Logical VM role."
  value       = var.role
}

output "ipv4_addresses" {
  description = "IPv4 addresses reported by QEMU guest agent."
  value       = proxmox_virtual_environment_vm.vm.ipv4_addresses
}

output "primary_ipv4_address" {
  description = "First non-loopback IPv4 address reported by QEMU guest agent."
  value       = element([for ip in flatten(proxmox_virtual_environment_vm.vm.ipv4_addresses) : ip if !startswith(ip, "127.")], 0)
}
