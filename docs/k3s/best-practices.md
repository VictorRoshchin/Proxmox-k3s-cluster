# Практики и антипаттерны K3s

## Лучшие практики

| Практика | Почему важно |
|---|---|
| Разделять provisioning и configuration | Terraform и Ansible остаются проще |
| Устанавливать K3s после готовности VM | меньше cloud-init race conditions |
| Отключать swap | требование Kubernetes-подобных сред |
| Включать `br_netfilter` и `overlay` | корректная работа network/container runtime |
| Проверять `kubectl get nodes` после deploy | быстрый health check |
| Хранить kubeconfig безопасно | доступ к cluster-admin |
| Использовать RBAC | ограничение прав |
| Делать backup до upgrade | возможность восстановления |
| Обновлять agents по одному | меньше downtime |
| Следить за CoreDNS | DNS критичен для приложений |
| Проверять storage backend | данные важнее Pod |
| Документировать выбранные addons | проще сопровождение |

## Антипаттерны

| Anti-pattern | Последствие |
|---|---|
| Один server node для production без backup | высокая точка отказа |
| Использовать local-path для критичных данных | потеря данных при проблеме node |
| Хранить kubeconfig в Git | полный доступ к кластеру утечёт |
| Подключать workers вручную | расхождение с automation |
| Игнорировать NotReady nodes | workloads деградируют |
| Устанавливать случайные ingress/storage addons без стандарта | сложно диагностировать |
| Запускать stateful workloads без resource requests | непредсказуемая стабильность |
| Не проверять certificate expiry | внезапные проблемы доступа |

## Для текущего проекта

- Текущая топология подходит для lab и обучения.
- Для production добавить HA server nodes или внешний backup/restore процесс.
- Для важных данных выбрать storage backend с репликацией.
- Для обновлений расширить Ansible roles отдельными upgrade tasks.
