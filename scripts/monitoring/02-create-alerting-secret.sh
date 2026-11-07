#!/usr/bin/env bash
# Frente 5: Secret com as credenciais dos destinos de alerta do Grafana.
# Rodar ANTES de sincronizar o Grafana (o pod não sobe sem este Secret).
set -euo pipefail
umask 077

echo "Preparando Secret de alertas do Grafana..."

kubectl get namespace monitoring >/dev/null

read -r -s -p "Integration Key do PagerDuty (Events API v2): " PAGERDUTY_INTEGRATION_KEY; echo
read -r -s -p "URL do webhook do Slack/Discord: " CHATOPS_WEBHOOK_URL; echo
# Recupera o mesmo token utilizado pelo receptor.
# O valor nao e exibido no terminal.
SELFHEALING_WEBHOOK_TOKEN="$(
  kubectl -n togglemaster get secret togglemaster-self-healing \
    -o jsonpath='{.data.WEBHOOK_TOKEN}' | base64 -d
)"

for name in PAGERDUTY_INTEGRATION_KEY CHATOPS_WEBHOOK_URL SELFHEALING_WEBHOOK_TOKEN; do
  if [[ -z "${!name}" ]]; then
    echo "ERRO: $name é obrigatório."
    exit 1
  fi
done

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

printf '%s' "$PAGERDUTY_INTEGRATION_KEY" > "$TEMP_DIR/PAGERDUTY_INTEGRATION_KEY"
printf '%s' "$CHATOPS_WEBHOOK_URL" > "$TEMP_DIR/CHATOPS_WEBHOOK_URL"
printf '%s' "$SELFHEALING_WEBHOOK_TOKEN" > "$TEMP_DIR/SELFHEALING_WEBHOOK_TOKEN"

unset PAGERDUTY_INTEGRATION_KEY CHATOPS_WEBHOOK_URL SELFHEALING_WEBHOOK_TOKEN

kubectl create secret generic togglemaster-grafana-alerting \
  --namespace monitoring \
  --from-file="$TEMP_DIR/PAGERDUTY_INTEGRATION_KEY" \
  --from-file="$TEMP_DIR/CHATOPS_WEBHOOK_URL" \
  --from-file="$TEMP_DIR/SELFHEALING_WEBHOOK_TOKEN" \
  --dry-run=client -o yaml |
kubectl apply -f -

echo "Secret de alertas configurado."
