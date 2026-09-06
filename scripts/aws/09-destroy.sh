#!/usr/bin/env bash

set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

ensure_aws_auth

echo
echo "ATENÇÃO: este procedimento destruirá a infraestrutura principal."
echo "O bucket de state e o orçamento AWS serão preservados."
echo
read -r -p 'Digite DESTROY para continuar: ' CONFIRMATION

if [[ "$CONFIRMATION" != "DESTROY" ]]; then
  echo "Destruição cancelada."
  exit 0
fi

terraform_run init \
  -reconfigure \
  -backend-config=backend.hcl

echo
echo "Gerando plano de destruição..."
terraform_run plan \
  -destroy \
  -out=aws-destroy.tfplan

echo
echo "Aplicando destruição..."
terraform_run apply aws-destroy.tfplan

echo
echo "Infraestrutura principal destruída."
echo "Execute scripts/aws/03-status.sh para conferir."
