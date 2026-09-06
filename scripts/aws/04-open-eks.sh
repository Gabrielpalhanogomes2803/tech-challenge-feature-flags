#!/usr/bin/env bash

set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

ensure_aws_auth

CLUSTER_NAME="${EKS_CLUSTER_NAME:-togglemaster-homolog-eks}"
PUBLIC_IP="${1:-$(curl -4fsS https://ifconfig.me)}"

python3 - "$PUBLIC_IP" <<'PY'
import ipaddress
import sys

address = ipaddress.ip_address(sys.argv[1])

if address.version != 4:
    raise SystemExit("É necessário informar um endereço IPv4 válido.")
PY

echo
echo "Liberando temporariamente o EKS para ${PUBLIC_IP}/32..."

UPDATE_ID="$(
  aws eks update-cluster-config \
    --region "$AWS_REGION_NAME" \
    --name "$CLUSTER_NAME" \
    --resources-vpc-config \
    "endpointPublicAccess=true,endpointPrivateAccess=true,publicAccessCidrs=[\"${PUBLIC_IP}/32\"]" \
    --query 'update.id' \
    --output text
)"

wait_eks_update "$CLUSTER_NAME" "$UPDATE_ID"

mkdir -p "$HOME/.kube"

aws eks update-kubeconfig \
  --region "$AWS_REGION_NAME" \
  --name "$CLUSTER_NAME"

echo
echo "=== ACESSO DO CLUSTER ==="

aws eks describe-cluster \
  --region "$AWS_REGION_NAME" \
  --name "$CLUSTER_NAME" \
  --query 'cluster.resourcesVpcConfig.{Public:endpointPublicAccess,Private:endpointPrivateAccess,CIDRs:publicAccessCidrs}'

echo
kubectl get nodes
