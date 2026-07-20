# Django demo manifests

Манифесты запускают Django demo application в K3s из образа:

```text
verrve/django-demo:latest
```

## Состав

| Файл | Назначение |
|---|---|
| `namespace.yaml` | Namespace `django-demo` |
| `configmap.yaml` | Несекретные переменные окружения Django |
| `secret.yaml` | Demo secret для `SECRET_KEY` |
| `deployment.yaml` | Deployment web-приложения |
| `service.yaml` | ClusterIP Service |
| `http-redirect-middleware.yaml` | Traefik Middleware для редиректа HTTP на HTTPS |
| `ingress.yaml` | HTTPS Ingress через Traefik и HTTP Ingress для редиректа |
| `tls-secret.example.yaml` | Шаблон TLS Secret для сертификата из Vault, не применяется автоматически |
| `hpa.yaml` | HorizontalPodAutoscaler |
| `kustomization.yaml` | Единая точка применения manifests |

## Запуск

Из корня репозитория:

```bash
kubectl apply -k manifests/django-demo
```

Или через kubeconfig, который забирает Ansible:

```bash
KUBECONFIG=ansible/artifacts/k3s.yaml kubectl apply -k manifests/django-demo
```

## Проверка

```bash
KUBECONFIG=ansible/artifacts/k3s.yaml kubectl -n django-demo get all
KUBECONFIG=ansible/artifacts/k3s.yaml kubectl -n django-demo get ingress
KUBECONFIG=ansible/artifacts/k3s.yaml kubectl -n django-demo logs deploy/django-demo
```

## Доступ

Ingress ожидает host:

```text
django-demo.k3s.home.verrve.ru
```

Для локальной проверки добавьте DNS-запись или временную запись в `/etc/hosts`, указывающую на IP node или LoadBalancer/Ingress endpoint:

```text
<K3S_NODE_OR_INGRESS_IP> django-demo.k3s.home.verrve.ru
```

После этого:

```bash
curl https://django-demo.k3s.home.verrve.ru/
```

HTTP-порт тоже обслуживается Traefik. Запрос на `http://django-demo.k3s.home.verrve.ru/` должен вернуть постоянный редирект на HTTPS:

```bash
curl -I http://django-demo.k3s.home.verrve.ru/
```

## TLS-сертификат из Vault

Ingress ссылается на Kubernetes Secret:

```text
django-demo-tls
```

Сейчас интеграции с Vault нет: сертификат и ключ добавляются вручную.

### Вариант 1. Создать Secret из файлов Vault

Если сертификат выпущен командой:

```bash
cd ext-datastore/vault
scripts/issue-cert.sh '*.k3s.home.verrve.ru' 720h verrve k3s.home.verrve.ru
```

то Secret можно создать так:

```bash
KUBECONFIG=ansible/artifacts/k3s.yaml \
kubectl -n django-demo create secret tls django-demo-tls \
  --cert=ext-datastore/vault/secrets/certs/_.k3s.home.verrve.ru/fullchain.pem \
  --key=ext-datastore/vault/secrets/certs/_.k3s.home.verrve.ru/tls.key
```

Если Secret уже существует:

```bash
KUBECONFIG=ansible/artifacts/k3s.yaml \
kubectl -n django-demo create secret tls django-demo-tls \
  --cert=ext-datastore/vault/secrets/certs/_.k3s.home.verrve.ru/fullchain.pem \
  --key=ext-datastore/vault/secrets/certs/_.k3s.home.verrve.ru/tls.key \
  --dry-run=client -o yaml | KUBECONFIG=ansible/artifacts/k3s.yaml kubectl apply -f -
```

### Вариант 2. Заполнить манифест вручную

Скопируйте шаблон:

```bash
cp manifests/django-demo/tls-secret.example.yaml manifests/django-demo/tls-secret.yaml
```

Вставьте в `tls.crt` содержимое `fullchain.pem`, а в `tls.key` содержимое `tls.key`, затем примените:

```bash
KUBECONFIG=ansible/artifacts/k3s.yaml kubectl apply -f manifests/django-demo/tls-secret.yaml
```

## Удаление

```bash
KUBECONFIG=ansible/artifacts/k3s.yaml kubectl delete -k manifests/django-demo
```

## Важное замечание

`secret.yaml` содержит демонстрационный `SECRET_KEY`. Для реального использования значение нужно заменить, а позднее перенести управление секретами в Vault или External Secrets.

`tls-secret.yaml` не хранится в Git, потому что содержит приватный ключ сертификата.
