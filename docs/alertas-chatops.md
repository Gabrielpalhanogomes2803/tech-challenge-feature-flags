# Fase 4 · Frente 5 — Alertas, Incidentes e ChatOps

Responsável: Susana.

Uma regra no Grafana Alerting detecta erros 5xx no `auth-service` e notifica
três destinos ao mesmo tempo: PagerDuty (incidente), Discord (ChatOps) e o
receptor de self-healing (webhook).

```text
auth-service (otelhttp) -> OTel Collector (spanmetrics) -> Prometheus
      -> Grafana Alerting: AuthHigh5xxRate (5xx > 5% por 1 min)
            |-> PagerDuty      (abre e fecha o incidente)
            |-> Discord        (mensagem detalhada FIRING / RESOLVED)
            '-> Webhook        (receptor de self-healing -> rollout restart)
```

## Decisões

| Tema | Escolha | Motivo |
|---|---|---|
| Origem do alerta | Grafana Alerting | O Alertmanager do Prometheus está desligado; uma regra notifica os três destinos. |
| Incidentes | PagerDuty | A Atlassian encerrou a venda do OpsGenie e anunciou o fim do suporte; o PagerDuty tem plano gratuito e integração nativa (Events API v2). |
| ChatOps | Discord | Canal já usado pelo grupo; integração nativa no Grafana. |
| Configuração | Provisionamento por arquivo | Versionado no Git e aplicado pelo Argo CD; nada é configurado pela interface. |
| Segredos | Secret `togglemaster-grafana-alerting` | Chaves fora do Git, lidas pelo Grafana como variáveis de ambiente. |

## Regra AuthHigh5xxRate

Avaliada a cada 30s; dispara quando o valor fica acima de 0,05 por 1 minuto.

```promql
(sum(rate(traces_span_metrics_calls_total{service_name="auth-service", span_kind="SPAN_KIND_SERVER", http_response_status_code=~"5.."}[1m])) or vector(0))
/
sum(rate(traces_span_metrics_calls_total{service_name="auth-service", span_kind="SPAN_KIND_SERVER"}[1m]))
```

Rótulos enviados: `alertname=AuthHigh5xxRate`, `severity=critical`,
`service=auth-service`, `deployment=auth-service`, `namespace=togglemaster`.

## Arquivos

| Arquivo | Para quê |
|---|---|
| `gitops/monitoring/grafana/dashboards/alerting-configmap.yaml` | Regra, contact points, política de roteamento e template da mensagem |
| `gitops/monitoring/grafana/dashboards/kustomization.yaml` | Inclui o ConfigMap na Application `togglemaster-monitoring-dashboard` |
| `gitops/monitoring/grafana/values.yaml` | `envFromSecret`, montagem do ConfigMap e `root_url` dos links |
| `scripts/monitoring/02-create-alerting-secret.sh` | Cria o Secret com as três credenciais |
| `scripts/aws/05-bootstrap-cluster.sh` | Chama o script acima ao recriar o cluster |
| `observability/local/alerting/` e `docker-compose.alerting.yml` | Teste local com a stack de observabilidade |

O ConfigMap não usa o campo `alerting:` do chart porque o Helm interpretaria os
`{{ }}` dos templates. Os templates usam `.Labels` em vez de `$labels` porque o
Grafana troca qualquer `$PALAVRA` por variável de ambiente.

## Implantação na AWS

1. Criar o Secret **antes** de sincronizar o Grafana (sem ele o pod fica em
   `CreateContainerConfigError`):
   `bash scripts/monitoring/02-create-alerting-secret.sh`
2. Merge na `main`: o Argo CD sincroniza `togglemaster-monitoring-dashboard` e
   `togglemaster-grafana`.
3. Mudanças só no ConfigMap exigem reiniciar o Grafana:
   `kubectl -n monitoring rollout restart deployment/togglemaster-grafana`
4. Conferir em *Alerting → Alert rules* (pasta ToggleMaster) e testar cada
   contact point com o botão *Test*.

Depende do OpenTelemetry Collector (frente 3) para existir a métrica
`traces_span_metrics_calls_total`.

## Teste local

Com as chaves exportadas no terminal (`PAGERDUTY_INTEGRATION_KEY` e
`CHATOPS_WEBHOOK_URL`), na raiz do repositório:

```bash
docker compose --project-directory . \
  -f observability/local/docker-compose.observability.yml \
  -f observability/local/docker-compose.alerting.yml up
python3 observability/local/gerar_telemetria.py --segundos 300 --taxa-erro 0.2
```

A regra vai para Pending em cerca de 30s e para Firing 1 minuto depois; ao fim
do script, volta a Normal e chegam as mensagens RESOLVED.

## Evidências

Prints da regra em Firing, do incidente no PagerDuty e das mensagens FIRING e
RESOLVED no Discord: `docs/evidencias/frente5/` (sem chaves ou URLs de webhook
visíveis).
