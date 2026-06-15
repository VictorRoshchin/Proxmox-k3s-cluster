# Практики и антипаттерны Terraform

## Лучшие практики

| Практика | Почему важно |
|---|---|
| Держать Terraform ответственным за инфраструктуру | не смешивать provisioning и configuration management |
| Использовать Ansible для настройки ОС | задачи ОС идемпотентнее в Ansible |
| Фиксировать providers в lock file | воспроизводимый init |
| Не коммитить state | state может содержать sensitive данные |
| Не коммитить `.env` и реальные `*.tfvars` | защита credentials |
| Использовать `for_each` со стабильными ключами | меньше случайных пересозданий |
| Проверять `plan` перед `apply` | видно destructive changes |
| Использовать `fmt` | единый стиль HCL |
| Использовать `validate` | ранняя диагностика ошибок |
| Минимизировать cloud-init | меньше first boot race conditions |
| Генерировать inventory из outputs/resources | нет статических IP |
| Разделять dev/stage/prod state | меньше blast radius |
| Делать backup state | восстановление после ошибок |
| Ограничивать права Proxmox пользователя | принцип least privilege |
| Использовать remote backend для команды | locking и общий source of truth |
| Документировать переменные | onboarding быстрее |
| Избегать ручных изменений в Proxmox | меньше drift |
| Использовать понятные VMID ranges | проще диагностика |
| Держать secrets вне HCL | меньше утечек |
| Проверять provider changelog перед upgrade | меньше breaking changes |

## Антипаттерны

| Anti-pattern | Последствие |
|---|---|
| Устанавливать K3s через Terraform `local-exec` | state зависит от конфигурационного шага |
| Держать IP workers вручную в inventory | рассинхронизация после пересоздания VM |
| Использовать `count` для именованных VM | риск index shift |
| Редактировать state руками | повреждение state |
| Запускать apply параллельно с двух машин | state race |
| Хранить пароль Proxmox в Git | компрометация инфраструктуры |
| Игнорировать drift | неожиданные изменения при apply |
| Делать один огромный root module для нескольких сред | сложно сопровождать |
| Обновлять providers без review | непредсказуемые изменения поведения |
| Использовать provisioners для всего | слабая идемпотентность |

## Production-рекомендации

Для production стоит добавить:

- remote backend с locking;
- отдельные tfvars/state на окружение;
- CI pipeline для `fmt`, `validate`, `plan`;
- manual approval перед `apply`;
- секреты через vault/CI variables;
- регулярный backup state.
