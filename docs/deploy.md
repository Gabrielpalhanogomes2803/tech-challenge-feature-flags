# Deploy do Projeto

## Requisitos

- Docker
- Docker Compose
- Kubernetes
- kubectl
- Conta AWS (para ambiente em nuvem)

---

## Execução Local

Iniciar os containers:

```bash
docker compose up -d
```

Verificar os containers:

```bash
docker compose ps
```

Visualizar logs:

```bash
docker compose logs
```

Parar ambiente:

```bash
docker compose down
```

---

## Deploy Kubernetes

Criar namespace

```bash
kubectl apply -f k8s/namespace.yaml
```

Criar ConfigMap

```bash
kubectl apply -f k8s/configmap.yaml
```

Criar Secret

```bash
kubectl apply -f k8s/secret.yaml
```

Criar bancos PostgreSQL

```bash
kubectl apply -f k8s/postgres-auth.yaml
kubectl apply -f k8s/postgres-main.yaml
```

Criar Deployments

```bash
kubectl apply -f k8s/deployments/
```

Criar Services

```bash
kubectl apply -f k8s/services/
```

Criar Ingress

```bash
kubectl apply -f k8s/ingress.yaml
```

Criar HPA

```bash
kubectl apply -f k8s/hpa/
```

---

## Verificações

```bash
kubectl get pods -A
kubectl get svc -A
kubectl get ingress -A
kubectl get hpa -A
```
