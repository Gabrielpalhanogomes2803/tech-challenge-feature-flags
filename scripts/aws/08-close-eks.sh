#!/usr/bin/env bash

set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

ensure_aws_auth

CLUSTER_NAME="${EKS_CLUSTER_NAME:-togglemaster-homolog-eks}"

echo
echo "Fechando o endpoint público do EKS..."

UPDATE_ID="$(
  aws eks update-cluster-config \
    --region "$AWS_REGION_NAME" \
    --name "$CLUSTER_NAME" \
    --resources-vpc-config \
    'endpointPublicAccess=false,endpointPrivateAccess=true' \
    --query 'update.id' \
    --output text
)"

wait_eks_update "$CLUSTER_NAME" "$UPDATE_ID"

echo
echo "=== ACESSO FINAL DO CLUSTER ==="

aws eks describe-cluster \
  --region "$AWS_REGION_NAME" \
  --name "$CLUSTER_NAME" \
  --query 'cluster.resourcesVpcConfig.{Public:endpointPublicAccess,Private:endpointPrivateAccess,CIDRs:publicAccessCidrs}'

echo
echo "Endpoint público fechado."
echo "O kubectl externo ficará indisponível até a próxima abertura autorizada."
