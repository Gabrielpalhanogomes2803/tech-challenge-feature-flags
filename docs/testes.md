# Testes Realizados

## Docker

- Build das imagens
- Execução dos containers
- Comunicação entre microsserviços

---

## Banco de Dados

Testes realizados:

- PostgreSQL Auth
- PostgreSQL Flags
- Criação automática das tabelas
- Inserção de dados

---

## Kubernetes

Validações realizadas:

- Namespace
- Deployments
- Services
- ConfigMap
- Secret
- Ingress
- HPA

---

## Comunicação

Testes realizados:

- Auth Service
- Flag Service
- Targeting Service
- Evaluation Service
- Analytics Service

---

## Endpoint de Avaliação

Teste realizado:

```
GET /evaluation/evaluate
```

Resultado:

```
{
  "flag_name":"test",
  "user_id":"1",
  "result":true
}
```

---

## Escalabilidade

Foi validado o funcionamento do Horizontal Pod Autoscaler utilizando consumo de CPU.

---

## Resultado

Todos os testes previstos foram executados com sucesso.
