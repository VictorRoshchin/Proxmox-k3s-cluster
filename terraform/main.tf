locals {
  # Terraform отвечает за инфраструктурный слой. K3s и другой софт ставятся Ansible
  # или отдельными playbooks, а не provisioner'ами Terraform.
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))

  k3s_vm_definitions = [
    for index in range(var.vm_count) : {
      index      = index
      role       = index == 0 ? "master" : "worker"
      role_index = index == 0 ? 1 : index
      name       = index == 0 ? "${var.vm_base_name}-master-1" : "${var.vm_base_name}-worker-${index}"
      vm_id      = var.vm_id_start + index
    }
  ]

  k3s_vms = {
    for vm in local.k3s_vm_definitions : vm.name => vm
  }

  inventory_vms = [
    for name, vm in module.k3s_vms : {
      hostname = name
      role     = local.k3s_vms[name].role
      alias    = local.k3s_vms[name].role == "master" ? format("master-%02d", local.k3s_vms[name].role_index) : format("worker-%02d", local.k3s_vms[name].role_index)
      ip       = vm.primary_ipv4_address
    }
  ]

  inventory_masters = [
    for vm in local.inventory_vms : vm if vm.role == "master"
  ]

  inventory_workers = [
    for vm in local.inventory_vms : vm if vm.role == "worker"
  ]
}

resource "proxmox_download_file" "ubuntu_cloud_image" {
  # Proxmox сам скачивает Ubuntu cloud image и сохраняет его как import content.
  content_type = "import"
  datastore_id = var.image_storage
  node_name    = var.proxmox_node
  url          = var.cloud_image_url
  file_name    = var.cloud_image_file_name
  overwrite    = false
}

module "k3s_vms" {
  source = "./modules/proxmox-cloud-vm"

  for_each = local.k3s_vms

  name               = each.value.name
  role               = each.value.role
  description        = "Ubuntu 24.04 cloud-init VM for k3s ${each.value.role}. Managed by Terraform."
  tags               = ["k3s", "terraform", "ubuntu", each.value.role]
  node_name          = var.proxmox_node
  vm_id              = each.value.vm_id
  cpu_cores          = var.vm_cpu_cores
  memory_mb          = var.vm_memory_mb
  disk_size_gb       = var.vm_disk_size_gb
  disk_storage       = var.disk_storage
  cloud_init_storage = var.cloud_init_storage
  snippets_storage   = var.snippets_storage
  network_bridge     = var.network_bridge
  dns_servers        = var.dns_servers
  username           = var.vm_username
  ssh_public_key     = local.ssh_public_key
  image_file_id      = proxmox_download_file.ubuntu_cloud_image.id
}

module "standalone_vms" {
  source = "./modules/proxmox-cloud-vm"

  for_each = var.standalone_vms

  name               = each.value.name
  role               = each.value.role
  description        = coalesce(each.value.description, "Standalone Ubuntu 24.04 cloud-init VM. Managed by Terraform.")
  tags               = concat(["standalone", "terraform", "ubuntu"], each.value.tags)
  node_name          = var.proxmox_node
  vm_id              = each.value.vm_id
  cpu_cores          = coalesce(each.value.cpu_cores, var.vm_cpu_cores)
  memory_mb          = coalesce(each.value.memory_mb, var.vm_memory_mb)
  disk_size_gb       = coalesce(each.value.disk_size_gb, var.vm_disk_size_gb)
  disk_storage       = var.disk_storage
  cloud_init_storage = var.cloud_init_storage
  snippets_storage   = var.snippets_storage
  network_bridge     = var.network_bridge
  dns_servers        = var.dns_servers
  username           = var.vm_username
  ssh_public_key     = local.ssh_public_key
  image_file_id      = proxmox_download_file.ubuntu_cloud_image.id
}

resource "local_file" "ansible_inventory" {
  # Inventory генерируется только из фактически созданных k3s VM и их IP.
  filename        = abspath("${path.module}/${var.ansible_inventory_path}")
  file_permission = "0644"

  content = templatefile("${path.module}/templates/ansible_inventory.yml.tftpl", {
    ansible_user                 = var.vm_username
    ansible_ssh_private_key_file = var.ansible_ssh_private_key_file
    masters                      = local.inventory_masters
    workers                      = local.inventory_workers
  })
}
