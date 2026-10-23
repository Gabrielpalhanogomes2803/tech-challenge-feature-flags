#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "$0")/common.sh"

CLUSTER_NAME="${EKS_CLUSTER_NAME:-togglemaster-homolog-eks}"
EXPECTED_ACCOUNT="966523587984"

ensure_aws_auth

ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"

if [[ "$ACCOUNT" != "$EXPECTED_ACCOUNT" ]]; then
  echo "ERRO: conta AWS inesperada: $ACCOUNT"
  exit 1
fi

aws eks describe-cluster \
  --region "$AWS_REGION_NAME" \
  --name "$CLUSTER_NAME" \
  --query 'cluster.status' \
  --output text >/dev/null

aws eks update-kubeconfig \
  --region "$AWS_REGION_NAME" \
  --name "$CLUSTER_NAME"

echo
echo "===== CONTEXTO KUBERNETES ====="
kubectl config current-context

echo
echo "===== APLICAÇÕES ARGO CD ====="
kubectl get applications.argoproj.io -n argocd

echo
echo "===== PVCs DE MONITORAMENTO ====="
kubectl get pvc -n monitoring --ignore-not-found

echo
echo "===== VOLUMES PERSISTENTES ====="
kubectl get pv

echo
echo "ATENÇÃO: serão removidas as aplicações Argo CD"
echo "do ToggleMaster e os PVCs do namespace monitoring."
echo "O Terraform Destroy NÃO será executado."
echo

read -r -p 'Digite CLEANUP para continuar: ' CONFIRMATION

if [[ "$CONFIRMATION" != "CLEANUP" ]]; then
  echo "Limpeza cancelada."
  exit 0
fi

echo
echo "===== REMOVENDO APLICAÇÕES ARGO CD ====="

APPLICATIONS=(
  togglemaster-auth
  togglemaster-flag
  togglemaster-targeting
  togglemaster-evaluation
  togglemaster-analytics
  togglemaster-grafana
  togglemaster-loki
  togglemaster-prometheus
  togglemaster-monitoring-dashboard
)

for app in "${APPLICATIONS[@]}"; do
  kubectl delete applications.argoproj.io "$app" \
    -n argocd \
    --ignore-not-found \
    --wait=true \
    --timeout=180s
done

echo
echo "===== INVENTÁRIO EBS ANTES DA LIMPEZA ====="

INVENTORY_DIR="$PROJECT_ROOT/.cleanup-evidence"
mkdir -p "$INVENTORY_DIR"
chmod 700 "$INVENTORY_DIR"

INVENTORY_FILE="$INVENTORY_DIR/ebs-volumes.json"
PV_JSON="$(kubectl get pv -o json)"

printf '%s' "$PV_JSON" | python3 -c '
import json, sys

data = json.load(sys.stdin)
result = []

for pv in data.get("items", []):
    spec = pv.get("spec", {})
    claim = spec.get("claimRef", {})
    csi = spec.get("csi", {})

    if (
        claim.get("namespace") == "monitoring"
        and spec.get("storageClassName") == "gp3-monitoring"
        and csi.get("driver") == "ebs.csi.aws.com"
    ):
        result.append({
            "pv": pv["metadata"]["name"],
            "pvc": claim.get("name"),
            "volume_id": csi.get("volumeHandle")
        })

print(json.dumps(result, indent=2))
' > "$INVENTORY_FILE"

chmod 600 "$INVENTORY_FILE"

echo "Inventário salvo: $INVENTORY_FILE"
cat "$INVENTORY_FILE"
echo

echo "===== PVCs DE MONITORAMENTO ====="

PVC_JSON="$(kubectl get pvc -n monitoring -o json)"

PVC_NAMES="$(
  printf '%s' "$PVC_JSON" | python3 -c '
import json,sys
data=json.load(sys.stdin)
for pvc in data.get("items", []):
    name=pvc["metadata"]["name"]
    sc=pvc.get("spec",{}).get("storageClassName")
    if sc == "gp3-monitoring":
        print(name)
'
)"

if [[ -n "$PVC_NAMES" ]]; then
  echo "$PVC_NAMES"
  echo
  echo "ATENÇÃO: confirme que TODOS os PVCs listados pertencem ao ToggleMaster."
  read -r -p 'Digite DELETE-PVCS para excluir esses PVCs: ' PVC_CONFIRMATION

  if [[ "$PVC_CONFIRMATION" != "DELETE-PVCS" ]]; then
    echo "Exclusão dos PVCs cancelada. Terraform Destroy NÃO deve ser executado."
    exit 1
  fi

  while IFS= read -r pvc; do
    [[ -z "$pvc" ]] && continue
    kubectl delete pvc "$pvc" \
      -n monitoring \
      --wait=true \
      --timeout=180s
  done <<< "$PVC_NAMES"
else
  echo "Nenhum PVC gp3-monitoring encontrado."
fi

echo
echo "===== VERIFICAÇÃO DOS VOLUMES ====="
kubectl get pvc -n monitoring
kubectl get pv

echo
echo "Confira também os volumes EBS no console AWS."
echo "Não execute Terraform Destroy enquanto houver volumes"
echo "do laboratório pendentes de exclusão."
echo
echo "Limpeza Kubernetes concluída."
echo "Verifique os volumes EBS antes de executar o Terraform Destroy."
