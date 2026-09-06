#!/usr/bin/env bash

set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

ensure_aws_auth

test -f "$TERRAFORM_DIR/backend.hcl" || {
  echo "Arquivo terraform/backend.hcl não encontrado."
  exit 1
}

echo
echo "Inicializando Terraform..."
terraform_run init \
  -reconfigure \
  -backend-config=backend.hcl

echo
echo "Validando formatação..."
terraform_run fmt -recursive -check

echo
echo "Validando configuração..."
terraform_run validate

echo
echo "Gerando plano..."
terraform_run plan \
  -out=aws-provision.tfplan

echo
echo "Aplicando plano..."
terraform_run apply aws-provision.tfplan

echo
echo "Infraestrutura AWS provisionada."
