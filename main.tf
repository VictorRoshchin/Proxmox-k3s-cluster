locals {
  # Terraform отвечает за инфраструктурный слой: VM, диск, сеть и минимальный
  # bootstrap для SSH/QEMU agent. Конфигурирование ОС и k3s выполняет Ansible.
  vm_definitions = [
    for index in range(var.vm_count) : {
      index      = index
      role       = index == 0 ? "master" : "worker"
      role_index = index == 0 ? 1 : index
      name       = index == 0 ? "${var.vm_base_name}-master-1" : "${var.vm_base_name}-worker-${index}"
      vm_id      = var.vm_id_start + index
    }
  ]

  vms = {
    # for_each удобнее count: ключом ресурса становится стабильное имя ВМ.
    for vm in local.vm_definitions : vm.name => vm
  }

  inventory_vms = [
    for name, vm in proxmox_virtual_environment_vm.k3s : {
      hostname = name
      role     = local.vms[name].role
      alias    = local.vms[name].role == "master" ? format("master-%02d", local.vms[name].role_index) : format("worker-%02d", local.vms[name].role_index)
      ip       = element([for ip in flatten(vm.ipv4_addresses) : ip if !startswith(ip, "127.")], 0)
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

resource "proxmox_virtual_environment_file" "cloud_config" {
  # Для каждой ВМ создаём отдельный cloud-init user-data snippet.
  for_each = local.vms

  content_type = "snippets"
  datastore_id = var.snippets_storage
  node_name    = var.proxmox_node

  source_raw {
    file_name = "${each.value.name}.cloud-config.yaml"
    # Cloud-init оставлен только для инфраструктурного bootstrap:
    # hostname, SSH-доступ и QEMU guest agent для получения IP через Proxmox.
    data = "#cloud-config\n${yamlencode({
      hostname = each.value.name
      fqdn     = "${each.value.name}.local"

      manage_etc_hosts = true
      package_update   = true
      package_upgrade  = false
      ssh_pwauth       = false
      disable_root     = false

      apt = {
        conf = "Acquire::Retries \"10\";\nDPkg::Lock::Timeout \"120\";\n"
      }

      users = [
        {
          name                  = var.vm_username
          gecos                 = "Kubernetes administrator"
          groups                = "adm,cdrom,dip,lxd,sudo"
          shell                 = "/bin/bash"
          sudo                  = "ALL=(ALL) NOPASSWD:ALL"
          lock_passwd           = true
          "ssh-authorized-keys" = [trimspace(file(pathexpand(var.ssh_public_key_path)))]
        },
        {
          name                  = "root"
          lock_passwd           = true
          "ssh-authorized-keys" = [trimspace(file(pathexpand(var.ssh_public_key_path)))]
        }
      ]

      packages = [
        "qemu-guest-agent"
      ]

      runcmd = [
        "systemctl enable --now qemu-guest-agent"
      ]
    })}"
  }
}

resource "proxmox_virtual_environment_vm" "k3s" {
  # Создаём одну ВМ на каждый элемент local.vms.
  for_each = local.vms

  name        = each.value.name
  description = "Ubuntu 24.04 cloud-init VM for k3s ${each.value.role}. Managed by Terraform."
  tags        = ["k3s", "terraform", "ubuntu", each.value.role]

  node_name = var.proxmox_node
  vm_id     = each.value.vm_id

  started         = true
  on_boot         = true
  stop_on_destroy = true
  scsi_hardware   = "virtio-scsi-single"

  operating_system {
    type = "l26"
  }

  cpu {
    cores = var.vm_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.vm_memory_mb
  }

  agent {
    # QEMU guest agent нужен Terraform для получения реального IP ВМ.
    enabled = true
    timeout = "10m"
    trim    = true

    wait_for_ip {
      ipv4 = true
    }
  }

  disk {
    # Системный диск импортируется из cloud image, поэтому ручная установка ОС не нужна.
    datastore_id = var.disk_storage
    import_from  = proxmox_download_file.ubuntu_cloud_image.id
    interface    = "scsi0"
    size         = var.vm_disk_size_gb
    file_format  = "raw"
    iothread     = true
    discard      = "on"
  }

  initialization {
    # Cloud-init диск содержит network config и ссылку на user-data snippet.
    datastore_id      = var.cloud_init_storage
    interface         = "ide2"
    user_data_file_id = proxmox_virtual_environment_file.cloud_config[each.key].id

    dns {
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_device {
    # Стандартная virtio-сеть через bridge Proxmox.
    bridge = var.network_bridge
    model  = "virtio"
  }

  serial_device {}

  # Загружаемся сразу с импортированного системного диска.
  boot_order = ["scsi0"]
}

resource "local_file" "ansible_inventory" {
  # Inventory генерируется только из фактически созданных ресурсов и их IP.
  filename        = "${path.module}/${var.ansible_inventory_path}"
  file_permission = "0644"

  content = templatefile("${path.module}/templates/ansible_inventory.yml.tftpl", {
    ansible_user                 = var.vm_username
    ansible_ssh_private_key_file = var.ansible_ssh_private_key_file
    masters                      = local.inventory_masters
    workers                      = local.inventory_workers
  })
}
