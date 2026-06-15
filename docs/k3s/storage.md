# Storage в K3s

## Оглавление

- [PersistentVolume](#persistentvolume)
- [PersistentVolumeClaim](#persistentvolumeclaim)
- [StorageClass](#storageclass)
- [Local Path Provisioner](#local-path-provisioner)
- [Внешние хранилища](#внешние-хранилища)
- [Антипаттерны](#антипаттерны)

## PersistentVolume

PersistentVolume — объект Kubernetes, представляющий хранилище.

## PersistentVolumeClaim

PVC — запрос приложения на хранилище.

```mermaid
flowchart LR
    A[Pod] --> B[PVC]
    B --> C[PV]
    C --> D[Storage backend]
```

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

## StorageClass

StorageClass описывает, как динамически создавать PV.

```bash
sudo k3s kubectl get storageclass
```

## Local Path Provisioner

K3s включает local-path-provisioner. Он создаёт локальную директорию на node.

Плюсы:

- простота;
- работает без внешнего storage;
- удобно для dev/lab.

Ограничения:

- нет репликации;
- Pod с volume привязан к node;
- backup нужно проектировать отдельно.

## Внешние хранилища

Для production обычно рассматривают:

- NFS;
- iSCSI;
- Ceph RBD;
- Longhorn;
- cloud block storage.

Выбор зависит от требований к отказоустойчивости, latency и backup.

## Антипаттерны

| Ошибка | Последствие |
|---|---|
| Использовать local-path для критичных данных без backup | потеря данных при потере node |
| Не задавать requests storage | непредсказуемое потребление |
| Хранить database без понимания storage backend | риск corruption/performance issues |
| Смешивать storage классы без naming convention | сложно сопровождать |
