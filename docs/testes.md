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

Validações realizadas (manifests em `gitops/`, sincronizados pelo Argo CD):

- Namespace
- Deployments
- Services (ClusterIP)
- ServiceAccounts (evaluation e analytics, com EKS Pod Identity)
- Secret de runtime (`togglemaster-runtime-secrets`)
- HPA do evaluation-service
- Probes de readiness (`/health`) e liveness (`/live`)

Não há Ingress: os serviços são expostos apenas dentro do cluster (ClusterIP) e
o acesso externo nos testes é feito com `kubectl port-forward`
(`scripts/aws/06-validate.sh` e `scripts/aws/06-functional-test.sh`).
As configurações não sensíveis são passadas como variáveis de ambiente nos
próprios Deployments, sem ConfigMap.

---

## Health Checks

Cada serviço expõe dois endpoints:

| Endpoint | Probe | O que verifica |
|---|---|---|
| `/health` | readiness | Dependência real: PostgreSQL (auth, flag, targeting), Redis (evaluation), DynamoDB e SQS (analytics). Retorna `503` com `"status": "degraded"` se a dependência falhar. |
| `/live` | liveness | Apenas se o processo responde, para o pod não ser reiniciado por falha de uma dependência externa. |

Com isso, se o banco cair, o pod sai do Service (para de receber tráfego) em vez
de responder `ok` e falhar silenciosamente nas requisições.

Exemplo de resposta saudável:

```
{"database":"up","status":"ok"}
```

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
kubectl port-forward -n togglemaster service/evaluation-service 18004:8004
GET http://127.0.0.1:18004/evaluate?user_id=1&flag_name=test
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

O evaluation-service, que recebe o maior volume de requisições, possui um
Horizontal Pod Autoscaler (`gitops/services/evaluation/hpa.yaml`):

- mínimo de 1 e máximo de 4 réplicas;
- alvo de 70% de uso de CPU em relação ao `requests` do container;
- janela de estabilização de 120 s para reduzir réplicas.

As métricas de CPU vêm do add-on `metrics-server` do EKS, criado pelo Terraform
(`terraform/modules/eks/main.tf`). O Argo CD ignora o campo `replicas` do
Deployment para não desfazer o que o HPA decide.

Para validar:

```
kubectl get hpa -n togglemaster
kubectl top pods -n togglemaster
```

---

## Resultado

Todos os testes previstos foram executados com sucesso.
