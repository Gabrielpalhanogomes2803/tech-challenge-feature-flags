# Arquitetura do Sistema

## Visão Geral

O ToggleMaster foi desenvolvido utilizando uma arquitetura baseada em microsserviços, onde cada serviço possui uma responsabilidade específica e se comunica através de APIs REST.

## Componentes

### Auth Service (Go)

Responsável pela autenticação dos microsserviços utilizando API Keys.

Porta:

```
8001
```

Banco:

- PostgreSQL (auth_db)

---

### Flag Service (Python)

Responsável pelo gerenciamento das Feature Flags.

Porta:

```
8002
```

Banco:

- PostgreSQL (flags_db)

---

### Targeting Service (Python)

Responsável pelas regras de segmentação das Feature Flags.

Porta:

```
8003
```

Banco:

- PostgreSQL (flags_db)

---

### Evaluation Service (Go)

Responsável por avaliar uma Feature Flag considerando:

- Flag habilitada
- Regras de segmentação
- Cache Redis

Também publica eventos para Analytics.

Porta:

```
8004
```

---

### Analytics Service (Python)

Recebe e processa eventos de utilização das Feature Flags.

Porta:

```
8005
```

---

## Banco de Dados

Foram utilizados dois bancos PostgreSQL.

### auth_db

Tabela:

- api_keys

### flags_db

Tabelas:

- flags
- targeting_rules

---

## Infraestrutura Kubernetes

- Namespace
- ConfigMap
- Secret
- Deployments
- Services
- Ingress NGINX
- Horizontal Pod Autoscaler (HPA)

---

## Cloud AWS

Durante a implantação foram utilizados:

- Amazon EKS
- Amazon ECR
- Amazon ElastiCache Redis
- Amazon DynamoDB
- Amazon SQS

Todos os recursos em nuvem foram removidos ao final dos testes para evitar custos.
