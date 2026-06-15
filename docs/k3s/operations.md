# Эксплуатация K3s

## Оглавление

- [Проверка состояния](#проверка-состояния)
- [Обновление](#обновление)
- [Backup](#backup)
- [Restore](#restore)
- [Масштабирование](#масштабирование)
- [Обслуживание nodes](#обслуживание-nodes)

## Проверка состояния

```bash
sudo k3s kubectl get nodes -o wide
sudo k3s kubectl get pods -A
systemctl status k3s
systemctl status k3s-agent
```

## Обновление

Текущие Ansible roles устанавливают K3s, если `/usr/local/bin/k3s` отсутствует. Полная upgrade-оркестрация пока не реализована.

Безопасный upgrade-подход:

1. backup;
2. обновить server;
3. проверить API;
4. обновлять agents по одному;
5. проверить workloads.

## Backup

Для single-server K3s с SQLite важно сохранять:

- datastore;
- manifests;
- важные Secrets;
- external storage данные;
- Terraform state;
- Ansible inventory/artifacts при необходимости.

## Restore

Restore должен быть протестирован до production-использования. Непроверенный backup — это гипотеза, не гарантия.

## Масштабирование

Worker nodes добавляются так:

1. увеличить `vm_count`;
2. выполнить `make apply`;
3. выполнить `make ansible`.

Terraform создаст VM и обновит inventory. Ansible подключит новых workers к master.

## Обслуживание nodes

Перед работами на node:

```bash
sudo k3s kubectl cordon <node>
sudo k3s kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
```

После работ:

```bash
sudo k3s kubectl uncordon <node>
```

