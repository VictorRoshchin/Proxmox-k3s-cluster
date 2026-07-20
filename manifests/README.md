# Kubernetes manifests

Эта директория содержит plain Kubernetes manifests для K3s. Это промежуточный этап перед переходом к Helm charts: сначала фиксируем рабочие Kubernetes objects в явном YAML, затем обобщаем их в chart.

## Приложения

| Директория | Назначение |
|---|---|
| `django-demo/` | Django demo application из образа `verrve/django-demo:latest` |

## Общий workflow

Применить manifests:

```bash
KUBECONFIG=ansible/artifacts/k3s.yaml kubectl apply -k manifests/django-demo
```

Проверить:

```bash
KUBECONFIG=ansible/artifacts/k3s.yaml kubectl -n django-demo get all,ingress,hpa
```

Удалить:

```bash
KUBECONFIG=ansible/artifacts/k3s.yaml kubectl delete -k manifests/django-demo
```
