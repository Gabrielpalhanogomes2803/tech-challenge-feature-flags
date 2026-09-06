#!/usr/bin/env bash

set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

ensure_aws_auth

kubectl get namespace argocd >/dev/null 2>&1 || {
  echo "O Argo CD não está acessível."
  echo "Execute antes:"
  echo "  ./scripts/aws/04-open-eks.sh"
  echo "  ./scripts/aws/05-bootstrap-cluster.sh"
  exit 1
}

echo "================================================"
echo " ACESSO LOCAL AO ARGO CD"
echo "================================================"
echo
echo "No Mac, abra outro terminal e execute:"
echo
echo "ssh -L 8080:127.0.0.1:8080 infra@2.25.122.150"
echo
echo "Depois abra: https://localhost:8080"
echo "Usuário: admin"
echo
echo "Para consultar a senha inicial na VPS:"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"
echo
echo "Mantenha este terminal aberto durante o acesso."
echo

kubectl port-forward \
  --namespace argocd \
  service/argocd-server \
  8080:443
