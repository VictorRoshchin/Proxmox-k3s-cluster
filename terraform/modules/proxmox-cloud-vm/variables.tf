variable "name" {
  description = "VM name."
  type        = string
}

variable "role" {
  description = "Logical VM role."
  type        = string
}

variable "description" {
  description = "VM description."
  type        = string
}

variable "tags" {
  description = "VM tags."
  type        = list(string)
  default     = []
}

variable "node_name" {
  description = "Proxmox node name."
  type        = string
}

variable "vm_id" {
  description = "Proxmox VMID."
  type        = number
}

variable "cpu_cores" {
  description = "vCPU cores."
  type        = number
}

variable "memory_mb" {
  description = "Dedicated memory in megabytes."
  type        = number
}

variable "disk_size_gb" {
  description = "System disk size in gigabytes."
  type        = number
}

variable "disk_storage" {
  description = "Proxmox datastore for VM disks."
  type        = string
}

variable "cloud_init_storage" {
  description = "Proxmox datastore for cloud-init disks."
  type        = string
}

variable "snippets_storage" {
  description = "Proxmox datastore for cloud-init snippets."
  type        = string
}

variable "network_bridge" {
  description = "Proxmox network bridge."
  type        = string
}

variable "dns_servers" {
  description = "DNS servers for cloud-init network config."
  type        = list(string)
}

variable "username" {
  description = "Linux administrator user."
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key content."
  type        = string
}

variable "image_file_id" {
  description = "Proxmox import file ID used as VM disk source."
  type        = string
}
