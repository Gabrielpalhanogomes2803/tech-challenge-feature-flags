# ToggleMaster — Vistoria de observabilidade (23/10/2026)

## Escopo
Validação da infraestrutura e dos componentes de observabilidade da Fase 4: EKS, Argo CD, Prometheus, Blackbox Exporter, Alloy, Loki e Grafana. Evidências coletadas em comandos executados no AWS CloudShell. Esta vistoria não substitui os testes de instrumentação distribuída, alertas ou self-healing dos demais responsáveis.

## Evidências observadas
- Argo CD: 11 aplicações listadas como `Synced` e `Healthy`.
- EKS: dois nós `Ready`; cinco deployments de microsserviços com duas réplicas disponíveis cada.
- Monitoramento: deployments Alloy, Blackbox Exporter, Grafana, kube-state-metrics e Prometheus server disponíveis; Loki em StatefulSet com uma réplica; node-exporter em dois nós.
- PVCs: Loki 8 GiB, Grafana 5 GiB e Prometheus 8 GiB, todos `Bound`.
- Blackbox/Prometheus: cinco séries ativas `probe_success{job="togglemaster-http-health"}`, com labels de serviço, valor 1; as séries antigas sem label expiraram.
- Grafana: dashboard `ToggleMaster | Operations Center`, UID `togglemaster-eks-infra`, com 37 itens (32 painéis e 5 linhas). No momento da inspeção do pod, a versão carregada era 8.
- Grafana → Loki: consulta HTTP `/loki/api/v1/labels` retornou `status=success`, incluindo `container`, `service_name`, `pod` e `stream`.
- Loki, janela de 30 minutos: `flag-service`, `targeting-service` e `analytics-service` retornaram 100 entradas cada (limite da consulta). `auth-service` e `evaluation-service` retornaram zero nesse intervalo.
- Kubernetes: logs estruturados em JSON de inicialização de `auth-service` e `evaluation-service` disponíveis em stdout/stderr, anteriores à janela de 30 minutos.
- Loki, janela de três horas: `auth-service` retornou 2 registros e `evaluation-service`, 6, incluindo `service_started`, `redis_connected` e `sqs_client_initialized`. Assim, a ingestão dos cinco microsserviços foi demonstrada, embora não se tenha verificado a geração contínua de eventos por todos eles.

## Ajuste versionado
Dashboard elevado à versão 9. As consultas dos painéis 50, 51, 52, 70 e 71 agora filtram `service!=""`, para excluir séries antigas de sondagem sem identificação. Não houve mudança de configuração do Alloy, Loki ou reinício de pods.

**Importante:** a alteração está no Git; a sincronização do Argo CD e o carregamento da versão 9 pelo Grafana devem ser confirmados no cluster. O funcionamento visual de todos os painéis não foi verificado por navegador.

## Próximas verificações
1. Confirmar Argo CD `Synced/Healthy` após o commit e a versão 9 no dashboard montado no Grafana.
2. Conferir métricas de CPU/memória e logs diretamente no dashboard, incluindo formatação JSON.
3. Executar teste de carga e documentar evidências, caso ainda não realizado.
4. Coordenar com João o OpenTelemetry Collector e evitar duplicidade de ingestão com o Alloy já enviando logs diretamente ao Loki.
5. Deixar APM/tracing, alertas/ChatOps e self-healing para seus respectivos responsáveis.

## Comandos de conferência
```bash
kubectl -n argocd get applications
kubectl -n monitoring exec deployment/togglemaster-grafana -- \
  sh -c 'grep -m1 "\"version\"" /var/lib/grafana/dashboards/togglemaster/eks-infrastructure.json'
kubectl -n monitoring get pods,pvc
```

## Observação operacional
Não excluir ou desligar recursos AWS sem aprovação e sem avaliar o impacto nos demais integrantes da equipe. Mesmo sem nós de trabalho, EKS, volumes EBS e outros recursos podem continuar gerando custos.
