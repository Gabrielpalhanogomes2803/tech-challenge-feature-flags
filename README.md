# ToggleMaster - Tech Challenge

## Sobre o projeto

O ToggleMaster é uma plataforma de Feature Flags baseada em microsserviços, desenvolvida como Tech Challenge.

O sistema permite criar, consultar e avaliar Feature Flags de forma escalável utilizando Docker, Kubernetes e serviços da AWS.

---

## Arquitetura

O projeto é composto pelos seguintes microsserviços:

- Auth Service (Go)
- Flag Service (Python)
- Targeting Service (Python)
- Evaluation Service (Go)
- Analytics Service (Python)

Banco de dados:

- PostgreSQL (Auth)
- PostgreSQL (Flags)

Infraestrutura:

- Docker
- Docker Compose
- Kubernetes
- NGINX Ingress
- Horizontal Pod Autoscaler (HPA)

Cloud:

- Amazon EKS
- Amazon ECR
- Amazon SQS
- Amazon DynamoDB
- Amazon ElastiCache (Redis)

---

## Estrutura do projeto

```
.
├── analytics-service/
├── auth-service/
├── evaluation-service/
├── flag-service/
├── targeting-service/
├── docker-compose.yml
├── k8s/
├── scripts/
├── docs/
└── README.md
```

---

## Execução local

```bash
docker compose up -d
```

Verificar:

```bash
docker compose ps
```

---

## Deploy Kubernetes

Os manifestos encontram-se em:

```
k8s/
```

Aplicação:

```bash
kubectl apply -f k8s/
```

---

## Funcionalidades

- Feature Flags
- Avaliação de Flags
- Regras de Segmentação
- Cache Redis
- Eventos para Analytics
- Escalonamento automático (HPA)
- Ingress NGINX

---

## Testes realizados

- Deploy Docker
- Deploy Kubernetes
- Comunicação entre microsserviços
- Banco PostgreSQL
- ConfigMaps
- Secrets
- Ingress
- HPA
- Avaliação de Feature Flags

---

## Tecnologias

- Go
- Python
- Flask
- PostgreSQL
- Docker
- Kubernetes
- AWS
- Redis

---

## Autores

Gabriel Gomes

Tech Challenge — Arquitetura de Microsserviços
