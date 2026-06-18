terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = var.snippets_storage
  node_name    = var.node_name

  source_raw {
    file_name = "${var.name}.cloud-config.yaml"
    data = "#cloud-config\n${yamlencode({
      hostname = var.name
      fqdn     = "${var.name}.local"

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
          name                  = var.username
          gecos                 = "Infrastructure administrator"
          groups                = "adm,cdrom,dip,lxd,sudo"
          shell                 = "/bin/bash"
          sudo                  = "ALL=(ALL) NOPASSWD:ALL"
          lock_passwd           = true
          "ssh-authorized-keys" = [var.ssh_public_key]
        },
        {
          name                  = "root"
          lock_passwd           = true
          "ssh-authorized-keys" = [var.ssh_public_key]
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

resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.name
  description = var.description
  tags        = var.tags

  node_name = var.node_name
  vm_id     = var.vm_id

  started         = true
  on_boot         = true
  stop_on_destroy = true
  scsi_hardware   = "virtio-scsi-single"

  operating_system {
    type = "l26"
  }

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  agent {
    enabled = true
    timeout = "10m"
    trim    = true

    wait_for_ip {
      ipv4 = true
    }
  }

  disk {
    datastore_id = var.disk_storage
    import_from  = var.image_file_id
    interface    = "scsi0"
    size         = var.disk_size_gb
    file_format  = "raw"
    iothread     = true
    discard      = "on"
  }

  initialization {
    datastore_id      = var.cloud_init_storage
    interface         = "ide2"
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id

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
    bridge = var.network_bridge
    model  = "virtio"
  }

  serial_device {}

  boot_order = ["scsi0"]
}
