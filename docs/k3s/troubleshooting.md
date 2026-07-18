# Устранение неполадок K3s

## Оглавление

- [Node NotReady](#node-notready)
- [Certificate issues](#certificate-issues)
- [Networking issues](#networking-issues)
- [Storage issues](#storage-issues)
- [Pod scheduling issues](#pod-scheduling-issues)
- [Cluster bootstrap issues](#cluster-bootstrap-issues)
- [Addon issues](#addon-issues)
- [Upgrade issues](#upgrade-issues)
- [Быстрый чеклист](#быстрый-чеклист)

## Node NotReady

Симптомы:

```bash
sudo k3s kubectl get nodes
```

Node в состоянии `NotReady`.

Диагностика:

```bash
journalctl -u k3s -n 200
journalctl -u k3s-agent -n 200
sudo k3s kubectl describe node <node>
sudo k3s kubectl get events -A --sort-by=.lastTimestamp
```

Причины:

- CNI не стартовал;
- kubelet не готов;
- проблемы DNS/маршрутизации;
- не загружены kernel modules;
- container runtime не запускает Pods;
- node не видит API Server.

Решения:

- проверить `br_netfilter` и `overlay`;
- проверить service status;
- проверить доступ worker к master `:6443`;
- проверить свободное место на диске;
- посмотреть conditions в `kubectl describe node`.

## Certificate issues

Симптомы:

- `x509: certificate signed by unknown authority`;
- kubeconfig не подключается;
- API отклоняет запросы;
- ошибка из-за IP/DNS, которого нет в certificate SAN.

Диагностика:

```bash
sudo k3s kubectl cluster-info
openssl s_client -connect <master-ip>:6443
grep server ansible/artifacts/k3s.yaml
```

Решения:

- проверить kubeconfig server address;
- не оставлять `127.0.0.1` в kubeconfig для внешнего kubectl;
- проверить `tls-san` для master IP/DNS;
- проверить время на nodes;
- пересоздать kubeconfig через Ansible.

## Networking issues

Симптомы:

- Pod не видит Service;
- CoreDNS restart loop;
- Ingress недоступен;
- worker node не подключается;
- Pod на разных nodes не видят друг друга.

Диагностика:

```bash
sudo k3s kubectl get pods -A
sudo k3s kubectl -n kube-system logs -l k8s-app=kube-dns
sudo k3s kubectl get svc,endpoints,endpointslice -A
sudo k3s kubectl get ingress,ingressclass -A
```

Решения:

- проверить CoreDNS;
- проверить endpoints у Service;
- проверить firewall между nodes;
- проверить flannel logs;
- проверить, что Pod CIDR не конфликтует с LAN;
- проверить selector Service.

## Storage issues

Симптомы:

- PVC висит `Pending`;
- Pod не стартует из-за volume;
- данные пропали после пересоздания Pod на другой node;
- StatefulSet Pod не может переехать.

Диагностика:

```bash
sudo k3s kubectl get pvc,pv -A
sudo k3s kubectl describe pvc <name>
sudo k3s kubectl get storageclass
sudo k3s kubectl describe pod <pod>
```

Решения:

- проверить default StorageClass;
- помнить ограничения local-path;
- проверить node affinity у PV;
- для важных данных использовать внешний storage;
- проверить reclaim policy перед удалением PVC.

## Pod scheduling issues

Симптомы:

- Pod в `Pending`;
- scheduler пишет `Insufficient cpu`;
- taints мешают запуску;
- Pod не помещается из-за volume node affinity.

Диагностика:

```bash
sudo k3s kubectl describe pod <pod>
sudo k3s kubectl describe node <node>
sudo k3s kubectl get nodes --show-labels
```

Решения:

- добавить resources;
- увеличить VM CPU/RAM;
- проверить taints/tolerations;
- проверить nodeSelector/affinity;
- добавить worker nodes;
- для server node решить, должен ли он принимать workloads.

## Cluster bootstrap issues

Симптомы:

- worker не присоединяется;
- `k3s-agent` падает;
- token rejected;
- Ansible зависает на ожидании API.

Диагностика:

```bash
systemctl status k3s-agent
journalctl -u k3s-agent -n 200
curl -k https://<master-ip>:6443
```

Причины:

- неверный token;
- worker не видит master;
- master API ещё не готов;
- firewall блокирует `6443`;
- generated inventory содержит старый IP;
- время на nodes сильно расходится.

Решения:

- повторить `make ansible`;
- проверить generated inventory;
- проверить `hostvars` master token в Ansible run;
- проверить сетевую доступность master;
- проверить time sync.

## Addon issues

Симптомы:

- Traefik не стартует;
- HelmChart stuck;
- ServiceLB не выдаёт внешний доступ;
- cert-manager webhook не отвечает.

Диагностика:

```bash
sudo k3s kubectl -n kube-system get helmchart,helmchartconfig
sudo k3s kubectl -n kube-system get pods
sudo k3s kubectl get crd
sudo k3s kubectl get events -A --sort-by=.lastTimestamp
```

Решения:

- проверить values HelmChartConfig;
- проверить CRD и webhook Pods;
- не ставить несколько ingress controllers без явного IngressClass;
- отключить конфликтующий packaged component через `--disable`;
- проверять addons по одному.

## Upgrade issues

Симптомы:

- node не возвращается после upgrade;
- API Server не стартует;
- Pods stuck после drain;
- CRD/webhook несовместимы с новой версией.

Диагностика:

```bash
sudo k3s --version
sudo k3s kubectl get nodes -o wide
sudo k3s kubectl get pods -A
sudo journalctl -u k3s -n 300
```

Решения:

- иметь backup до upgrade;
- обновлять agents по одному;
- проверять compatibility addons;
- читать release notes перед major/minor upgrade;
- иметь rollback plan.

## Быстрый чеклист

1. `systemctl status k3s` или `k3s-agent`.
2. `kubectl get nodes -o wide`.
3. `kubectl get pods -A`.
4. `kubectl get events -A --sort-by=.lastTimestamp`.
5. `kubectl describe node <node>`.
6. `kubectl describe pod <pod>`.
7. Проверить DNS/CoreDNS.
8. Проверить storage/PVC.
9. Проверить firewall и доступ к `:6443`.
10. Проверить время/timezone/time sync.
