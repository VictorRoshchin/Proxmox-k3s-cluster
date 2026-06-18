terraform {
  # Минимальная версия Terraform, с которой рассчитана эта конфигурация.
  required_version = ">= 1.8.0"

  required_providers {
    proxmox = {
      # Современный provider для Proxmox VE от bpg.
      source  = "bpg/proxmox"
      version = ">= 0.78.0, < 1.0.0"
    }
    local = {
      # Нужен только для генерации Ansible inventory после создания ВМ.
      source  = "hashicorp/local"
      version = ">= 2.5.0, < 3.0.0"
    }
  }
}

provider "proxmox" {
  # Данные подключения приходят из .env через переменные TF_VAR_*.
  endpoint = var.proxmox_api_url
  username = var.proxmox_user
  password = var.proxmox_password
  insecure = var.proxmox_tls_insecure

  # SSH используется provider'ом для загрузки cloud-init snippets на storage local.
  ssh {
    username = var.proxmox_ssh_username
    password = var.proxmox_password

    node {
      name    = var.proxmox_node
      address = var.proxmox_ssh_node_address
    }
  }
}
