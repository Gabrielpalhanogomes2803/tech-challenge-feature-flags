#!/usr/bin/env bash

set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

ensure_aws_auth
cd "$PROJECT_ROOT"

kubectl get nodes >/dev/null 2>&1 || {
  echo "O EKS não está acessível."
  echo "Execute: ./scripts/aws/04-open-eks.sh"
  exit 1
}

echo
echo "=== NODES ==="
kubectl get nodes

echo
echo "=== ARGO CD ==="
kubectl get applications \
  --namespace argocd \
  -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status'

python3 - <<'PY'
import json
import subprocess

data = json.loads(subprocess.check_output([
    "kubectl",
    "get",
    "applications",
    "--namespace",
    "argocd",
    "-o",
    "json",
], text=True))

expected = {
    "togglemaster-auth",
    "togglemaster-flag",
    "togglemaster-targeting",
    "togglemaster-evaluation",
    "togglemaster-analytics",
}

found = set()
errors = []

for item in data["items"]:
    name = item["metadata"]["name"]

    if name not in expected:
        continue

    found.add(name)
    sync = item.get("status", {}).get("sync", {}).get("status")
    health = item.get("status", {}).get("health", {}).get("status")

    if sync != "Synced" or health != "Healthy":
        errors.append(f"{name}: sync={sync}, health={health}")

missing = expected - found

if missing:
    errors.append("Aplicações ausentes: " + ", ".join(sorted(missing)))

if errors:
    raise SystemExit("\n".join(errors))

print("Argo CD: cinco aplicações Synced e Healthy.")
PY

echo
echo "=== DEPLOYMENTS ==="
kubectl get deployments --namespace togglemaster

for deployment in \
  auth-service \
  flag-service \
  targeting-service \
  evaluation-service \
  analytics-service
do
  kubectl rollout status \
    --namespace togglemaster \
    "deployment/$deployment" \
    --timeout=3m
done

echo
echo "=== HEALTH CHECKS ==="

declare -a PIDS=()

cleanup() {
  for pid in "${PIDS[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
}
trap cleanup EXIT

services=(
  "auth-service:18001:8001"
  "flag-service:18002:8002"
  "targeting-service:18003:8003"
  "evaluation-service:18004:8004"
  "analytics-service:18005:8005"
)

for item in "${services[@]}"; do
  IFS=: read -r service local_port service_port <<< "$item"

  kubectl port-forward \
    --namespace togglemaster \
    "service/$service" \
    "${local_port}:${service_port}" \
    >"/tmp/togglemaster-${service}.log" 2>&1 &

  PIDS+=("$!")
done

sleep 5

for item in "${services[@]}"; do
  IFS=: read -r service local_port service_port <<< "$item"

  response="$(
    curl -fsS \
      --max-time 10 \
      "http://127.0.0.1:${local_port}/health"
  )"

  echo "$service: $response"
done

echo
echo "=== DYNAMODB ==="
aws dynamodb scan \
  --region "$AWS_REGION_NAME" \
  --table-name ToggleMasterAnalytics \
  --select COUNT \
  --query '{Quantidade:Count,Verificados:ScannedCount}'

echo
echo "VALIDAÇÃO CONCLUÍDA COM SUCESSO."
