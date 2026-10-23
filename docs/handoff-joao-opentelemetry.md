# Handoff — João | OpenTelemetry Collector (Fase 4)

**Data:** 23/10/2026 · **Projeto:** ToggleMaster · **Responsável pela base de observabilidade:** Gabriel

## Situação verificada

- EKS: 2 nós monitorados, 5 microsserviços (`auth`, `flag`, `targeting`, `evaluation`, `analytics`), 10/10 réplicas disponíveis na vistoria.
- Argo CD: 11 Applications `Synced/Healthy`.
- Grafana: `ToggleMaster | Operations Center`, UID `togglemaster-eks-infra`, versão **9**, 37 elementos (32 painéis + 5 linhas).
- Prometheus + Blackbox Exporter: cinco endpoints `/health` com `probe_success=1` e HTTP 200; séries de latência exibidas no Grafana.
- Alloy: coleta logs Kubernetes e envia diretamente ao Loki. Loki recebeu registros de todos os cinco serviços, com ritmos diferentes.
- Fontes Grafana: Prometheus e Loki; dashboard provido por ConfigMap via Argo CD.

## Onde olhar no Git

- `gitops/monitoring/grafana/dashboards/eks-dashboard-configmap.yaml`
- `gitops/monitoring/grafana/values.yaml`
- `docs/observabilidade-vistoria-2026-10-23.md`
- `README.md`

## Próxima integração: OpenTelemetry

**Antes de implantar o Collector:** decidir com a equipe quais sinais ele receberá (traces, métricas, logs), de quais serviços e para quais destinos. O Alloy já encaminha logs diretamente ao Loki; habilitar uma segunda coleta dos mesmos stdout/stderr pode duplicar eventos e custos.

Sequência sugerida:
1. Definir topologia e responsabilidade de cada pipeline (Alloy x Collector).
2. Instrumentar serviços e configurar propagação de contexto, com Gustavo na frente de tracing/APM.
3. Validar endpoints, autenticação, permissões e limites dos receivers/exporters.
4. Implantar pelo GitOps e conferir `Synced/Healthy`, saúde do Collector e consultas no destino.
5. Fazer um teste de ponta a ponta com requisição identificável, preservando evidências.
6. Coordenar alertas com Susana e self-healing com Heloísa.

## Atenções encontradas

- Entradas com `JSONParserErr` no Loki/Grafana: mensagem `Value looks like object, but can't find closing '}' symbol`. Podem refletir parsing de linhas não JSON; não classificar automaticamente como falha de negócio.
- Alguns logs Python indicam uso de servidor de desenvolvimento. Revisar se for operar além do laboratório.
- `auth` e `evaluation` podem não emitir eventos em janelas curtas; sua ingestão já foi demonstrada em janelas maiores.
- Teste de carga e validação final de alertas/traces permanecem pendentes.

## Acesso operacional

```bash
kubectl -n argocd get applications
kubectl -n monitoring get pods,pvc
kubectl -n monitoring port-forward svc/togglemaster-grafana 3001:80
```

Dashboard no Grafana: **Dashboards → ToggleMaster → ToggleMaster | Operations Center**. Grafana é ClusterIP, sem endpoint público permanente.

## Encerramento AWS

A equipe deve aprovar o desligamento antes de qualquer `destroy`: Terraform controla recursos compartilhados do laboratório (EKS, bancos, rede, etc.). Verificar o plano de destruição e recursos externos ao state. Não remover backend S3 sem preservar o state necessário.

**Referência:** [Vistoria completa](observabilidade-vistoria-2026-10-23.md).
