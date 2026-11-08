#!/usr/bin/env bash
# Orquestrador de limpeza MANUAL, nao altera o S3 do Terraform state.
# Executar SOMENTE quando nao houver mais gravacao e evidencias a coletar.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
export AWS_PROFILE="${AWS_PROFILE_NAME:-togglemaster}"
export AWS_REGION="${AWS_REGION_NAME:-us-east-1}"
export AWS_DEFAULT_REGION="$AWS_REGION"
EXPECTED_ACCOUNT='966523587984'
EXPECTED_CLUSTER='togglemaster-homolog-eks'
[[ "$AWS_REGION" == 'us-east-1' ]] || { echo 'BLOQUEADO: regiao inesperada'; exit 2; }
actual="$(aws sts get-caller-identity --query Account --output text)"
[[ "$actual" == "$EXPECTED_ACCOUNT" ]] || { echo 'BLOQUEADO: conta AWS inesperada'; exit 2; }
[[ -f terraform/backend.hcl ]] || { echo 'BLOQUEADO: terraform/backend.hcl ausente'; exit 2; }
[[ -f terraform/terraform.tfvars ]] || { echo 'BLOQUEADO: terraform/terraform.tfvars ausente'; exit 2; }
[[ -x scripts/aws/09a-cleanup-kubernetes.sh ]] || { echo 'BLOQUEADO: 09a-cleanup-kubernetes.sh indisponivel'; exit 2; }
[[ -x scripts/aws/09-destroy.sh ]] || { echo 'BLOQUEADO: 09-destroy.sh indisponivel'; exit 2; }

printf 'Conta: %s | Regiao: %s | Cluster: %s\n' "$actual" "$AWS_REGION" "$EXPECTED_CLUSTER"
echo 'ANTES: salve evidencias e confirme que o cluster e seus dados podem ser eliminados.'
echo 'A limpeza Kubernetes remove aplicacoes/PVCs; o destroy elimina recursos Terraform.'
echo 'NAO execute se o kubectl estiver inacessivel. NAO ignore erros.'
read -r -p 'Para continuar, digite TOGGLEMASTER-DESMONTAR: ' answer
[[ "$answer" == 'TOGGLEMASTER-DESMONTAR' ]] || { echo 'Cancelado'; exit 0; }

command -v kubectl >/dev/null || { echo 'ERRO: kubectl ausente'; exit 1; }
current_cluster="$(aws eks describe-cluster --name "$EXPECTED_CLUSTER" --query 'cluster.name' --output text)"
[[ "$current_cluster" == "$EXPECTED_CLUSTER" ]] || { echo 'BLOQUEADO: cluster inesperado'; exit 2; }
context="$(kubectl config current-context)"
echo "Contexto kubectl: $context"
[[ "$context" == *"$EXPECTED_CLUSTER"* ]] || { echo 'BLOQUEADO: contexto kubectl nao corresponde ao cluster esperado'; exit 2; }
kubectl get nodes >/dev/null || { echo 'ERRO: cluster inacessivel. Abra acesso de forma autorizada antes do cleanup.'; exit 1; }

# Revisao exigida: script original 09a nao contempla todos os apps Fase 4.
for app in togglemaster-self-healing togglemaster-otel-collector togglemaster-alloy togglemaster-monitoring-blackbox; do
  if kubectl get applications.argoproj.io "$app" -n argocd >/dev/null 2>&1; then
    echo "Removendo Argo CD Application: $app"
    kubectl delete applications.argoproj.io "$app" -n argocd --wait=true --timeout=180s
  fi
done

bash scripts/aws/09a-cleanup-kubernetes.sh

echo 'Checando PVCs/PVs do monitoramento antes do Terraform destroy:'
kubectl get pvc -n monitoring --ignore-not-found || true
kubectl get pv || true
echo 'Confirme manualmente EBS e recursos dinamicos. O Terraform destroy exige sua confirmacao separada.'
read -r -p 'Digite OK-EBS-VERIFICADO para seguir: ' ebs_answer
[[ "$ebs_answer" == 'OK-EBS-VERIFICADO' ]] || { echo 'Parado antes do Terraform destroy'; exit 1; }
bash scripts/aws/09-destroy.sh

echo 'Destroy solicitado. Audite a conta com scripts/aws/10-audit-aws.sh.'
echo 'Bucket S3 do state, suas versoes e recursos nao geridos pelo Terraform EXIGEM procedimento separado.'
