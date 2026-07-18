# Storage в K3s

## Оглавление

- [Модель storage в Kubernetes](#модель-storage-в-kubernetes)
- [PersistentVolume](#persistentvolume)
- [PersistentVolumeClaim](#persistentvolumeclaim)
- [StorageClass](#storageclass)
- [Access Modes](#access-modes)
- [Reclaim Policy](#reclaim-policy)
- [Local Path Provisioner](#local-path-provisioner)
- [StatefulSet и volumes](#statefulset-и-volumes)
- [CSI](#csi)
- [Внешние хранилища](#внешние-хранилища)
- [Backup данных](#backup-данных)
- [Антипаттерны](#антипаттерны)

## Модель storage в Kubernetes

Pod эфемерен. Его можно удалить и пересоздать на другой node. Данные внутри container filesystem нельзя считать постоянными.

Для постоянных данных используются:

- `PersistentVolume`;
- `PersistentVolumeClaim`;
- `StorageClass`;
- CSI drivers или built-in provisioners.

```mermaid
flowchart LR
    APP[Application Pod] --> PVC[PersistentVolumeClaim]
    PVC --> PV[PersistentVolume]
    PV --> SC[StorageClass]
    SC --> BACKEND[Storage backend]
```

## PersistentVolume

PersistentVolume — объект Kubernetes, представляющий хранилище.

PV может быть:

- создан вручную;
- создан динамически через StorageClass.

## PersistentVolumeClaim

PVC — запрос приложения на хранилище.

Пример:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

Pod использует PVC как volume.

## StorageClass

StorageClass описывает, как динамически создавать PV.

Проверка:

```bash
sudo k3s kubectl get storageclass
sudo k3s kubectl describe storageclass <name>
```

Default StorageClass используется, если PVC не указал `storageClassName`.

## Access Modes

| Mode | Значение |
|---|---|
| `ReadWriteOnce` | Volume может быть смонтирован read-write одной node. |
| `ReadOnlyMany` | Volume может быть смонтирован read-only многими nodes. |
| `ReadWriteMany` | Volume может быть смонтирован read-write многими nodes. |
| `ReadWriteOncePod` | Volume доступен read-write одному Pod. |

Не каждый backend поддерживает все modes.

## Reclaim Policy

Reclaim policy определяет судьбу PV после удаления PVC.

| Policy | Поведение |
|---|---|
| `Delete` | Volume удаляется вместе с PVC. |
| `Retain` | Volume остаётся, требуется ручная очистка/повторное использование. |

Для важных данных нужно понимать, что произойдёт при удалении PVC.

## Local Path Provisioner

K3s включает local-path-provisioner. Он создаёт локальную директорию на node.

Плюсы:

- простота;
- работает без внешнего storage;
- удобно для dev/lab.

Ограничения:

- нет репликации;
- Pod с volume привязан к node;
- backup нужно проектировать отдельно;
- при потере node можно потерять данные;
- autoscheduling stateful workload может упереться в node affinity volume.

Проверка:

```bash
sudo k3s kubectl -n kube-system get deploy local-path-provisioner
sudo k3s kubectl get pv,pvc -A
```

## StatefulSet и volumes

StatefulSet часто использует `volumeClaimTemplates`, чтобы каждому Pod дать свой PVC.

Подходит для:

- баз данных;
- очередей;
- сервисов с устойчивой идентичностью.

Но StatefulSet не делает storage отказоустойчивым сам по себе. Репликация зависит от приложения или storage backend.

## CSI

CSI — Container Storage Interface. Через CSI Kubernetes работает с внешними storage systems.

Примеры:

- Longhorn;
- Ceph RBD/CephFS;
- NFS CSI;
- iSCSI CSI;
- cloud block storage.

CSI может добавлять:

- dynamic provisioning;
- snapshots;
- expansion;
- attach/detach;
- topology-aware scheduling.

## Внешние хранилища

Для production обычно рассматривают:

- NFS;
- iSCSI;
- Ceph RBD;
- Longhorn;
- cloud block storage.

Выбор зависит от требований к отказоустойчивости, latency, backup и доступному железу.

Для homelab с Proxmox возможные пути:

- NFS share с отдельного NAS;
- Longhorn на нескольких worker nodes;
- Ceph, если инфраструктура достаточно зрелая;
- local-path для некритичных данных.

## Backup данных

Backup Kubernetes manifests не равен backup данных.

Нужно отдельно бэкапить:

- PV data;
- database dumps;
- object storage;
- Vault data;
- K3s datastore;
- Terraform state.

Для критичных приложений должен быть restore test: поднять чистый workload и восстановить данные.

## Антипаттерны

| Ошибка | Последствие |
|---|---|
| Использовать local-path для критичных данных без backup | потеря данных при потере node |
| Не задавать requests storage | непредсказуемое потребление |
| Хранить database без понимания storage backend | риск corruption/performance issues |
| Смешивать storage classes без naming convention | сложно сопровождать |
| Считать StatefulSet заменой backup | StatefulSet не защищает данные |
| Удалять PVC без понимания reclaim policy | неожиданная потеря volume |
