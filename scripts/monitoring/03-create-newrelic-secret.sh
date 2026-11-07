#!/usr/bin/env bash
set -euo pipefail
umask 077

echo "Preparando Secret do New Relic..."

kubectl get namespace monitoring >/dev/null

read -r -s -p "New Relic License Key: " NEW_RELIC_LICENSE_KEY
echo

if [[ -z "$NEW_RELIC_LICENSE_KEY" ]]; then
  echo "ERRO: License Key obrigatoria."
  exit 1
fi

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

printf '%s' "$NEW_RELIC_LICENSE_KEY" \
  > "$TEMP_DIR/license-key"

unset NEW_RELIC_LICENSE_KEY

kubectl create secret generic newrelic-license \
  --namespace monitoring \
  --from-file="license-key=$TEMP_DIR/license-key" \
  --dry-run=client -o yaml |
  kubectl apply -f -

echo "Secret newrelic-license configurado."
