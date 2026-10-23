#!/usr/bin/env bash
set -euo pipefail
umask 077

echo "Preparando Secret administrativo do Grafana..."

kubectl get namespace monitoring >/dev/null

read -r -p "Usuário administrador: " GRAFANA_USER
read -r -s -p "Senha do Grafana: " GRAFANA_PASSWORD
echo

if [[ -z "$GRAFANA_USER" || -z "$GRAFANA_PASSWORD" ]]; then
  echo "ERRO: usuário e senha são obrigatórios."
  exit 1
fi

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

printf '%s' "$GRAFANA_USER" > "$TEMP_DIR/admin-user"
printf '%s' "$GRAFANA_PASSWORD" > "$TEMP_DIR/admin-password"

unset GRAFANA_USER GRAFANA_PASSWORD

kubectl create secret generic togglemaster-grafana-admin \
  --namespace monitoring \
  --from-file=admin-user="$TEMP_DIR/admin-user" \
  --from-file=admin-password="$TEMP_DIR/admin-password" \
  --dry-run=client -o yaml |
kubectl apply -f -

echo "Secret administrativo configurado."
