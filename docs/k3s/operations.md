# Эксплуатация K3s

## Оглавление

- [Проверка состояния](#проверка-состояния)
- [Управление workloads](#управление-workloads)
- [Конфигурация K3s](#конфигурация-k3s)
- [Запуск и systemd](#запуск-и-systemd)
- [Обновление](#обновление)
- [Upgrade orchestration](#upgrade-orchestration)
- [Backup](#backup)
- [Restore](#restore)
- [Масштабирование](#масштабирование)
- [Обслуживание nodes](#обслуживание-nodes)
- [Управление addons](#управление-addons)
- [Команды диагностики](#команды-диагностики)

## Проверка состояния

Базовые команды:

```bash
sudo k3s kubectl get nodes -o wide
sudo k3s kubectl get pods -A
sudo k3s kubectl get svc -A
sudo k3s kubectl get ingress -A
```

Проверка systemd services:

```bash
systemctl status k3s
systemctl status k3s-agent
```

На server node обычно активен `k3s`. На worker nodes активен `k3s-agent`.

Проверка версии:

```bash
sudo k3s --version
sudo k3s kubectl version
sudo k3s kubectl get nodes -o wide
```

## Управление workloads

Основные объекты:

```bash
sudo k3s kubectl get deploy,rs,pods
sudo k3s kubectl get daemonset,statefulset,job,cronjob -A
sudo k3s kubectl get configmap,secret -A
sudo k3s kubectl get pvc,pv,storageclass -A
```

Rollout:

```bash
sudo k3s kubectl rollout status deploy/<name>
sudo k3s kubectl rollout history deploy/<name>
sudo k3s kubectl rollout undo deploy/<name>
```

Логи и exec:

```bash
sudo k3s kubectl logs deploy/<name>
sudo k3s kubectl logs pod/<pod> -c <container>
sudo k3s kubectl exec -it pod/<pod> -- sh
```

## Конфигурация K3s

K3s можно конфигурировать аргументами запуска или файлом:

```text
/etc/rancher/k3s/config.yaml
```

Для server:

```yaml
node-name: k3s-master-1
write-kubeconfig-mode: "0644"
tls-san:
  - 192.168.31.174
disable:
  - servicelb
```

Для agent:

```yaml
server: https://192.168.31.174:6443
token: <cluster-token>
node-name: k3s-worker-1
```

В текущем проекте Ansible использует install script variables. Это работает, но для дальнейшего развития лучше вынести конфигурацию в templates:

- `templates/server-config.yaml.j2`;
- `templates/agent-config.yaml.j2`.

Так проще управлять addons, TLS SAN, flannel backend, node labels и taints.

## Запуск и systemd

Install script K3s создаёт systemd unit:

- `k3s.service` на server;
- `k3s-agent.service` на agents.

Полезные команды:

```bash
sudo systemctl daemon-reload
sudo systemctl restart k3s
sudo systemctl restart k3s-agent
sudo journalctl -u k3s -f
sudo journalctl -u k3s-agent -f
```

После изменения `/etc/rancher/k3s/config.yaml` нужен restart соответствующего сервиса.

## Обновление

Текущие Ansible roles устанавливают K3s, если `/usr/local/bin/k3s` отсутствует. Полная upgrade-оркестрация пока не реализована.

Безопасный upgrade-подход:

1. Зафиксировать текущие версии.
2. Сделать backup.
3. Проверить свободное место на nodes.
4. Обновить server node.
5. Проверить API Server и системные Pods.
6. Обновлять agents по одному.
7. После каждого agent проверять workloads.
8. Проверить cluster health и application health.

Проверка перед upgrade:

```bash
sudo k3s kubectl get nodes -o wide
sudo k3s kubectl get pods -A
sudo k3s kubectl get events -A --sort-by=.lastTimestamp
```

## Upgrade orchestration

Для ручного upgrade worker node:

```bash
sudo k3s kubectl cordon <node>
sudo k3s kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
```

После обновления:

```bash
sudo k3s kubectl uncordon <node>
```

Для server node в single-server кластере drain нужно применять осторожно: server одновременно control plane и worker. Если на нём есть пользовательские workloads, они могут быть выселены. Если ресурсов worker nodes мало, часть Pods может остаться `Pending`.

Для автоматизации можно рассмотреть:

- отдельные Ansible upgrade tasks;
- system-upgrade-controller;
- GitOps-managed upgrade plans.

Но до автоматизации важно иметь backup и понятный rollback plan.

## Backup

Для single-server K3s с SQLite важно сохранять:

- datastore;
- `/etc/rancher/k3s`;
- `/var/lib/rancher/k3s/server/manifests`;
- cluster token;
- kubeconfig;
- важные Kubernetes Secrets;
- persistent volumes;
- Terraform state;
- Ansible inventory/artifacts при необходимости.

Для embedded etcd используются snapshots. Для SQLite backup должен учитывать остановку или корректный snapshot файла datastore, чтобы избежать повреждённой копии.

Практический минимум для текущего проекта:

- backup `terraform/terraform.tfstate`;
- backup `ansible/artifacts/k3s.yaml`;
- backup K3s datastore на master;
- backup данных persistent volumes.

## Restore

Restore должен быть протестирован до production-использования. Непроверенный backup — это гипотеза, не гарантия.

Проверяемый restore workflow:

1. Поднять чистые VM.
2. Восстановить datastore или пересоздать кластер.
3. Восстановить manifests/addons.
4. Восстановить secrets.
5. Восстановить PV data.
6. Проверить приложения.

Если кластер пересоздаётся с нуля, старые kubeconfig/token могут стать недействительными. Это нужно явно учитывать в документации восстановления.

## Масштабирование

Worker nodes добавляются так:

1. увеличить `vm_count`;
2. выполнить `make apply`;
3. выполнить `make ansible`.

Terraform создаст VM и обновит inventory. Ansible подключит новых workers к master.

После добавления:

```bash
sudo k3s kubectl get nodes -o wide
sudo k3s kubectl describe node <new-node>
```

Масштабирование control plane требует отдельной архитектуры HA и в текущем проекте не реализовано.

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

Если используется local-path storage, drain может быть ограничен volumes, привязанными к node. Stateful workloads требуют отдельного плана.

## Управление addons

K3s addons могут управляться несколькими способами:

- bundled packaged components;
- manifests directory;
- Helm вручную;
- Ansible tasks;
- GitOps.

Рекомендуемый порядок зрелости:

1. Для базового bootstrap использовать Ansible.
2. Для приложений и addons использовать Helm.
3. Для постоянной эксплуатации перейти к GitOps.

Пример проверки packaged components:

```bash
sudo k3s kubectl -n kube-system get deploy,daemonset,svc
sudo k3s kubectl get helmchart -A
sudo k3s kubectl get helmchartconfig -A
```

## Команды диагностики

```bash
sudo k3s kubectl cluster-info
sudo k3s kubectl get componentstatuses
sudo k3s kubectl get events -A --sort-by=.lastTimestamp
sudo k3s kubectl top nodes
sudo k3s kubectl top pods -A
sudo k3s crictl ps
sudo k3s crictl images
sudo journalctl -u k3s -n 300
sudo journalctl -u k3s-agent -n 300
```

`componentstatuses` исторически полезен, но в новых Kubernetes-средах может быть ограниченно информативен. Для реальной диагностики лучше смотреть Pods, events, logs и node conditions.
