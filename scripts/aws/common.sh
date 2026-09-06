#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

AWS_PROFILE_NAME="${AWS_PROFILE_NAME:-togglemaster}"
AWS_TERRAFORM_PROFILE="${AWS_TERRAFORM_PROFILE:-togglemaster-terraform}"
AWS_REGION_NAME="${AWS_REGION_NAME:-us-east-1}"
TERRAFORM_IMAGE="${TERRAFORM_IMAGE:-togglemaster/terraform-aws:1.13}"

ensure_aws_auth() {
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
  unset AWS_SECURITY_TOKEN

  export AWS_PROFILE="$AWS_PROFILE_NAME"
  export AWS_REGION="$AWS_REGION_NAME"
  export AWS_DEFAULT_REGION="$AWS_REGION_NAME"

  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "Sessão AWS expirada. Iniciando autenticação remota..."
    aws login --profile "$AWS_PROFILE_NAME" --remote
  fi

  aws sts get-caller-identity \
    --query '{Account:Account,Arn:Arn}'
}

ensure_terraform_profile() {
  aws configure set \
    credential_process \
    "/usr/local/bin/aws configure export-credentials --profile $AWS_PROFILE_NAME --format process" \
    --profile "$AWS_TERRAFORM_PROFILE"

  aws configure set \
    region "$AWS_REGION_NAME" \
    --profile "$AWS_TERRAFORM_PROFILE"
}

ensure_terraform_image() {
  if ! docker image inspect "$TERRAFORM_IMAGE" >/dev/null 2>&1; then
    echo "Construindo imagem Terraform + AWS CLI..."

    docker build \
      -f "$PROJECT_ROOT/scripts/aws/Dockerfile.terraform-aws" \
      -t "$TERRAFORM_IMAGE" \
      "$PROJECT_ROOT/scripts/aws"
  fi
}

terraform_run() (
  cd "$TERRAFORM_DIR"

  ensure_terraform_profile
  ensure_terraform_image

  docker run --rm \
    -e AWS_PROFILE="$AWS_TERRAFORM_PROFILE" \
    -e AWS_REGION="$AWS_REGION_NAME" \
    -e AWS_DEFAULT_REGION="$AWS_REGION_NAME" \
    -e AWS_SDK_LOAD_CONFIG=1 \
    -v "$HOME/.aws:/root/.aws" \
    -v "$TERRAFORM_DIR:/workspace" \
    -w /workspace \
    "$TERRAFORM_IMAGE" "$@"
)

wait_eks_update() {
  local cluster_name="$1"
  local update_id="$2"
  local status

  while true; do
    status="$(
      aws eks describe-update \
        --region "$AWS_REGION_NAME" \
        --name "$cluster_name" \
        --update-id "$update_id" \
        --query 'update.status' \
        --output text
    )"

    echo "Status: $status"

    case "$status" in
      Successful) return 0 ;;
      Failed|Cancelled)
        echo "A atualização do EKS falhou."
        return 1
        ;;
    esac

    sleep 15
  done
}
