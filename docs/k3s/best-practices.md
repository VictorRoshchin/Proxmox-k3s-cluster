# Практики и антипаттерны K3s

## Лучшие практики

| Практика | Почему важно |
|---|---|
| Разделять provisioning и configuration | Terraform и Ansible остаются проще |
| Устанавливать K3s после готовности VM | меньше cloud-init race conditions |
| Помнить, что server node также worker | правильное планирование ресурсов и taints |
| Отключать swap | требование Kubernetes-подобных сред |
| Включать `br_netfilter` и `overlay` | корректная работа network/container runtime |
| Проверять `kubectl get nodes` после deploy | быстрый health check |
| Хранить kubeconfig безопасно | доступ к cluster-admin |
| Использовать RBAC | ограничение прав |
| Делать backup до upgrade | возможность восстановления |
| Обновлять agents по одному | меньше downtime |
| Использовать drain/cordon при обслуживании | меньше неожиданных disruptions |
| Следить за CoreDNS | DNS критичен для приложений |
| Проверять storage backend | данные важнее Pod |
| Документировать выбранные addons | проще сопровождение |
| Фиксировать версии Helm charts и images | воспроизводимость deployments |
| Вводить addons постепенно | проще диагностика и rollback |

## Антипаттерны

| Anti-pattern | Последствие |
|---|---|
| Один server node для production без backup | высокая точка отказа |
| Считать server node только control plane | недооценка нагрузки, потому что там есть kubelet/containerd |
| Использовать local-path для критичных данных | потеря данных при проблеме node |
| Хранить kubeconfig в Git | полный доступ к кластеру утечёт |
| Подключать workers вручную | расхождение с automation |
| Игнорировать NotReady nodes | workloads деградируют |
| Устанавливать случайные ingress/storage addons без стандарта | сложно диагностировать |
| Запускать stateful workloads без resource requests | непредсказуемая стабильность |
| Не проверять certificate expiry | внезапные проблемы доступа |
| Считать Secret шифрованием | base64 не защищает данные |
| Использовать default ServiceAccount везде | лишние API permissions |
| Делать upgrade без backup | риск долгого восстановления |
| Смешивать manual kubectl changes и GitOps без правил | drift и непонятное состояние |

## Для текущего проекта

- Текущая топология подходит для lab и обучения.
- Server node можно оставить schedulable, пока ресурсов достаточно.
- Для production добавить HA server nodes или внешний backup/restore процесс.
- Для важных данных выбрать storage backend с репликацией.
- Для обновлений расширить Ansible roles отдельными upgrade tasks.
- Для addons перейти к Helm values и затем GitOps.
- Для секретов постепенно внедрить Vault и убрать чувствительные данные из Git.

## Рекомендуемый baseline

Минимальный baseline для homelab:

- `make deploy` воспроизводимо поднимает кластер;
- `make ansible` идемпотентен;
- `kubectl get nodes -o wide` показывает все nodes `Ready`;
- kubeconfig endpoint указывает на IP master;
- timezone и time sync настроены;
- swap отключён;
- kernel modules и sysctl применены;
- backup state и kubeconfig выполняется перед крупными изменениями.
