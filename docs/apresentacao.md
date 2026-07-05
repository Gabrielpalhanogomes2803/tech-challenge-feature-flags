# Roteiro da Apresentação

## 1. Introdução

Apresentação do projeto ToggleMaster.

Objetivo:

Implementar uma plataforma de Feature Flags utilizando arquitetura de microsserviços.

---

## 2. Arquitetura

Apresentação dos cinco microsserviços.

- Auth Service
- Flag Service
- Targeting Service
- Evaluation Service
- Analytics Service

---

## 3. Docker

Apresentação do ambiente local.

- Docker Compose
- Containers

---

## 4. Kubernetes

Apresentação dos recursos:

- Namespace
- Deployments
- Services
- ConfigMap
- Secret
- Ingress
- HPA

---

## 5. Demonstração

Executar:

```
GET /auth/health
```

```
GET /evaluation/health
```

```
GET /evaluation/evaluate?user_id=1&flag_name=test
```

Demonstrar resposta:

```json
{
  "flag_name":"test",
  "user_id":"1",
  "result":true
}
```

---

## 6. AWS

Explicar a utilização de:

- Amazon EKS
- Amazon ECR
- Amazon RDS
- Amazon ElastiCache
- Amazon DynamoDB
- Amazon SQS

---

## 7. Encerramento

Apresentar a organização do repositório, documentação e principais aprendizados durante o desenvolvimento do projeto.
