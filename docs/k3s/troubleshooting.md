# Устранение неполадок K3s

## Оглавление

- [Node NotReady](#node-notready)
- [Certificate issues](#certificate-issues)
- [Networking issues](#networking-issues)
- [Storage issues](#storage-issues)
- [Pod scheduling issues](#pod-scheduling-issues)
- [Cluster bootstrap issues](#cluster-bootstrap-issues)

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
```

Причины:

- CNI не стартовал;
- kubelet не готов;
- проблемы DNS/маршрутизации;
- не загружены kernel modules.

Решения:

- проверить `br_netfilter` и `overlay`;
- проверить service status;
- проверить доступ worker к master `:6443`.

## Certificate issues

Симптомы:

- `x509: certificate signed by unknown authority`;
- kubeconfig не подключается;
- API отклоняет запросы.

Диагностика:

```bash
sudo k3s kubectl cluster-info
openssl s_client -connect <master-ip>:6443
```

Решения:

- проверить kubeconfig server address;
- не копировать kubeconfig между кластерами без правки endpoint;
- проверить время на nodes.

## Networking issues

Симптомы:

- Pod не видит Service;
- CoreDNS restart loop;
- Ingress недоступен.

Диагностика:

```bash
sudo k3s kubectl get pods -A
sudo k3s kubectl -n kube-system logs -l k8s-app=kube-dns
sudo k3s kubectl get svc,endpoints -A
```

Решения:

- проверить CoreDNS;
- проверить endpoints у Service;
- проверить firewall между nodes;
- проверить flannel logs.

## Storage issues

Симптомы:

- PVC висит `Pending`;
- Pod не стартует из-за volume;
- данные пропали после пересоздания Pod на другой node.

Диагностика:

```bash
sudo k3s kubectl get pvc,pv -A
sudo k3s kubectl describe pvc <name>
sudo k3s kubectl get storageclass
```

Решения:

- проверить default StorageClass;
- помнить ограничения local-path;
- для важных данных использовать внешний storage.

## Pod scheduling issues

Симптомы:

- Pod в `Pending`;
- scheduler пишет `Insufficient cpu`;
- taints мешают запуску.

Диагностика:

```bash
sudo k3s kubectl describe pod <pod>
sudo k3s kubectl describe node <node>
```

Решения:

- добавить resources;
- увеличить VM CPU/RAM;
- проверить taints/tolerations;
- добавить worker nodes.

## Cluster bootstrap issues

Симптомы:

- worker не присоединяется;
- `k3s-agent` падает;
- token rejected.

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
- firewall блокирует `6443`.

Решения:

- повторить `make ansible`;
- проверить generated inventory;
- проверить `hostvars` master token в Ansible run;
- проверить сетевую доступность master.
