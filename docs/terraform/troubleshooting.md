# Устранение неполадок Terraform

## Оглавление

- [Provider registry](#provider-registry)
- [Proxmox API](#proxmox-api)
- [State](#state)
- [Cloud-init и IP discovery](#cloud-init-и-ip-discovery)
- [Inventory generation](#inventory-generation)

## Provider registry

| Симптом | Причина | Диагностика | Решение |
|---|---|---|---|
| `Invalid provider registry host` | registry недоступен или proxy возвращает HTML | `wget https://registry.terraform.io/.well-known/terraform.json` внутри контейнера | настроить DNS, VPN, proxy |
| `Missing required provider` | не выполнен init после добавления provider | `terraform providers` | `make init` |
| `Failed to query available provider packages` | нет доступа к registry | проверить сеть контейнера | proxy/VPN/DNS |

## Proxmox API

| Симптом | Причина | Решение |
|---|---|---|
| `401 Unauthorized` | неверный пользователь/пароль/realm | проверить `.env` |
| `403 Permission check failed` | недостаточно прав | выдать права на VM/storage |
| `node does not exist` | указан IP вместо имени ноды | поставить имя ноды Proxmox |
| `storage does not support snippets` | не включён content type | включить Snippets для storage |

## State

| Симптом | Причина | Решение |
|---|---|---|
| Terraform создаёт уже существующую VM | state потерян | восстановить state или import |
| lock не снимается | прерванный apply | убедиться, что процесса нет, затем снять lock |
| план предлагает неожиданный replace | изменён identity-параметр | проверить VMID, name, disk import |

## Cloud-init и IP discovery

| Симптом | Причина | Решение |
|---|---|---|
| ожидание IP зависает | QEMU guest agent не установлен/не запущен | проверить console VM и cloud-init logs |
| IP пустой в output | guest agent не вернул IPv4 | проверить DHCP и `systemctl status qemu-guest-agent` |
| cloud-init final failed | apt/network problem | смотреть `/var/log/cloud-init.log` |

## Inventory generation

| Симптом | Причина | Решение |
|---|---|---|
| `hosts.yml` не создан | apply не дошёл до `local_file` | проверить ошибки VM/IP |
| Ansible подключается не туда | старый generated inventory | повторить `make apply` |
| private key path неверный | `ansible_ssh_private_key_file` не соответствует окружению | исправить `terraform/terraform.tfvars` и `make apply` |
