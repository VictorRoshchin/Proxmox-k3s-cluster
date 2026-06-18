variable "proxmox_api_url" {
  # Передаётся из .env как TF_VAR_proxmox_api_url.
  description = "URL API Proxmox VE, например https://192.168.31.200:8006/."
  type        = string
  sensitive   = true
}

variable "proxmox_user" {
  # Например root@pam или terraform@pve.
  description = "Пользователь Proxmox VE, например root@pam."
  type        = string
  sensitive   = true
}

variable "proxmox_password" {
  # Используется и для API, и для SSH в текущей простой схеме.
  description = "Пароль пользователя Proxmox VE."
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  # Для домашнего Proxmox обычно true, потому что сертификат самоподписанный.
  description = "Разрешить самоподписанный TLS-сертификат Proxmox VE."
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Имя узла Proxmox VE, на котором будут созданы ВМ."
  type        = string
}

variable "proxmox_ssh_username" {
  description = "SSH-пользователь Proxmox VE для загрузки cloud-init snippets."
  type        = string
  default     = "root"
}

variable "proxmox_ssh_node_address" {
  description = "IP-адрес или DNS-имя узла Proxmox VE для SSH-подключения."
  type        = string
  default     = "192.168.31.200"
}

variable "disk_storage" {
  # Для тонких дисков VM на стандартной установке Proxmox часто используется local-lvm.
  description = "Хранилище Proxmox для дисков ВМ."
  type        = string
  default     = "local-lvm"
}

variable "image_storage" {
  # На этом storage должен быть разрешён content type Import.
  description = "Хранилище Proxmox для загруженного Ubuntu cloud image."
  type        = string
  default     = "local"
}

variable "snippets_storage" {
  # На этом storage должен быть разрешён content type Snippets.
  description = "Хранилище Proxmox для cloud-init snippets. На этом storage должен быть включен content type Snippets."
  type        = string
  default     = "local"
}

variable "cloud_init_storage" {
  description = "Хранилище Proxmox для cloud-init диска ВМ."
  type        = string
  default     = "local-lvm"
}

variable "cloud_image_url" {
  description = "URL Ubuntu cloud image, который Proxmox скачает через API."
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "cloud_image_file_name" {
  description = "Имя файла Ubuntu cloud image в Proxmox."
  type        = string
  default     = "noble-server-cloudimg-amd64.qcow2"
}

variable "vm_count" {
  # Первая ВМ всегда master, остальные получают роль worker.
  description = "Количество ВМ. Первая ВМ будет master, остальные worker."
  type        = number
  default     = 3

  validation {
    condition     = var.vm_count >= 1
    error_message = "vm_count должен быть не меньше 1."
  }
}

variable "vm_cpu_cores" {
  description = "Количество vCPU на одну ВМ."
  type        = number
  default     = 2

  validation {
    condition     = var.vm_cpu_cores >= 1
    error_message = "vm_cpu_cores должен быть не меньше 1."
  }
}

variable "vm_memory_mb" {
  description = "Количество RAM на одну ВМ в мегабайтах."
  type        = number
  default     = 2048

  validation {
    condition     = var.vm_memory_mb >= 1024
    error_message = "vm_memory_mb должен быть не меньше 1024."
  }
}

variable "vm_disk_size_gb" {
  description = "Размер системного диска одной ВМ в гигабайтах."
  type        = number
  default     = 35

  validation {
    condition     = var.vm_disk_size_gb >= 20
    error_message = "vm_disk_size_gb должен быть не меньше 20."
  }
}

variable "vm_base_name" {
  description = "Базовое имя ВМ."
  type        = string
  default     = "k3s"
}

variable "vm_username" {
  description = "Основной пользователь внутри Ubuntu ВМ."
  type        = string
  default     = "victor"
}

variable "ansible_ssh_private_key_file" {
  description = "Путь к приватному SSH-ключу, который Ansible будет использовать для подключения к ВМ."
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "ansible_inventory_path" {
  description = "Путь к YAML inventory, который Terraform генерирует для Ansible."
  type        = string
  default     = "../ansible/inventories/generated/hosts.yml"
}

variable "ssh_public_key_path" {
  # Terraform читает содержимое этого файла и добавляет ключ в authorized_keys.
  description = "Путь к публичному SSH-ключу для доступа к пользователю vm_username и root."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "network_bridge" {
  description = "Bridge Proxmox для сетевого интерфейса ВМ."
  type        = string
  default     = "vmbr0"
}

variable "dns_servers" {
  description = "DNS-серверы, которые будут переданы в cloud-init."
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "vm_id_start" {
  description = "Начальный VMID. Каждая следующая ВМ получит VMID + 1."
  type        = number
  default     = 300
}

variable "standalone_vms" {
  description = "Standalone VM, не входящие в k3s-кластер, например VM для Vault."
  type = map(object({
    name         = string
    role         = optional(string, "standalone")
    vm_id        = number
    cpu_cores    = optional(number)
    memory_mb    = optional(number)
    disk_size_gb = optional(number)
    description  = optional(string)
    tags         = optional(list(string), [])
  }))
  default = {}
}
