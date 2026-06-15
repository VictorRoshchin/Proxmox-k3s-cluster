output "created_vms" {
  # После apply этот output помогает быстро увидеть VMID и IP-адреса.
  description = "Созданные виртуальные машины и их VMID."
  value = {
    for name, vm in proxmox_virtual_environment_vm.k3s : name => {
      vm_id          = vm.vm_id
      name           = vm.name
      role           = local.vms[name].role
      ipv4_addresses = vm.ipv4_addresses
    }
  }
}

output "master_ip" {
  description = "IPv4-адрес master-узла k3s."
  value       = local.inventory_masters[0].ip
}

output "worker_ips" {
  description = "IPv4-адреса worker-узлов k3s."
  value       = [for vm in local.inventory_workers : vm.ip]
}

output "inventory_path" {
  description = "Путь к сгенерированному Ansible inventory."
  value       = local_file.ansible_inventory.filename
}
