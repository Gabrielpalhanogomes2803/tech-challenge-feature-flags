#!/usr/bin/env bash

set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

ensure_aws_auth
cd "$PROJECT_ROOT"

kubectl get secret togglemaster-runtime-secrets \
  --namespace togglemaster >/dev/null

API_KEY="$(
  kubectl get secret togglemaster-runtime-secrets \
    --namespace togglemaster \
    -o jsonpath='{.data.SERVICE_API_KEY}' |
  base64 -d
)"

TEST_FLAG="fiap-demo-$(date +%H%M%S)"

BEFORE_COUNT="$(
  aws dynamodb scan \
    --region "$AWS_REGION_NAME" \
    --table-name ToggleMasterAnalytics \
    --select COUNT \
    --consistent-read \
    --query Count \
    --output text
)"

declare -a PIDS=()

cleanup() {
  unset API_KEY

  for pid in "${PIDS[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
}
trap cleanup EXIT

kubectl port-forward \
  --namespace togglemaster \
  service/flag-service \
  18002:8002 >/tmp/togglemaster-flag-test.log 2>&1 &
PIDS+=("$!")

kubectl port-forward \
  --namespace togglemaster \
  service/targeting-service \
  18003:8003 >/tmp/togglemaster-targeting-test.log 2>&1 &
PIDS+=("$!")

kubectl port-forward \
  --namespace togglemaster \
  service/evaluation-service \
  18004:8004 >/tmp/togglemaster-evaluation-test.log 2>&1 &
PIDS+=("$!")

sleep 5

echo "=== CRIANDO FLAG: $TEST_FLAG ==="

curl --fail-with-body -sS \
  -X POST http://127.0.0.1:18002/flags \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d "{
    \"name\": \"$TEST_FLAG\",
    \"description\": \"Teste funcional automatizado FIAP\",
    \"is_enabled\": true
  }"

echo
echo "=== CRIANDO REGRA DE 50% ==="

curl --fail-with-body -sS \
  -X POST http://127.0.0.1:18003/rules \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d "{
    \"flag_name\": \"$TEST_FLAG\",
    \"is_enabled\": true,
    \"rules\": {
      \"type\": \"PERCENTAGE\",
      \"value\": 50
    }
  }"

echo
echo "=== PRIMEIRA AVALIAÇÃO ==="

curl --fail-with-body -sS \
  "http://127.0.0.1:18004/evaluate?user_id=user-123&flag_name=$TEST_FLAG"

echo
echo "=== SEGUNDA AVALIAÇÃO ==="

curl --fail-with-body -sS \
  "http://127.0.0.1:18004/evaluate?user_id=user-123&flag_name=$TEST_FLAG"

echo
echo "=== CACHE ==="

sleep 3

kubectl logs \
  --namespace togglemaster \
  deployment/evaluation-service \
  --since=5m |
grep -E "Cache (MISS|HIT).*${TEST_FLAG}" |
tail -10

echo
echo "=== DYNAMODB ==="

for attempt in $(seq 1 12); do
  AFTER_COUNT="$(
    aws dynamodb scan \
      --region "$AWS_REGION_NAME" \
      --table-name ToggleMasterAnalytics \
      --select COUNT \
      --consistent-read \
      --query Count \
      --output text
  )"

  if (( AFTER_COUNT >= BEFORE_COUNT + 2 )); then
    break
  fi

  sleep 5
done

echo "Antes: $BEFORE_COUNT"
echo "Depois: $AFTER_COUNT"

if (( AFTER_COUNT < BEFORE_COUNT + 2 )); then
  echo "Os dois eventos ainda não apareceram no DynamoDB."
  exit 1
fi

echo
echo "TESTE FUNCIONAL CONCLUÍDO COM SUCESSO."
