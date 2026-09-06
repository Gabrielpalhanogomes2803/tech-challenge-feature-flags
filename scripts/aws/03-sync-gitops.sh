#!/usr/bin/env bash

set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

ensure_aws_auth

cd "$PROJECT_ROOT"

git switch main
git pull --ff-only origin main

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Existem alterações locais. Faça commit antes de sincronizar o GitOps."
  git status --short
  exit 1
fi

REDIS_HOST="$(
  aws elasticache describe-replication-groups \
    --region "$AWS_REGION_NAME" \
    --replication-group-id togglemaster-homolog-redis \
    --query 'ReplicationGroups[0].NodeGroups[0].PrimaryEndpoint.Address' \
    --output text
)"

REDIS_PORT="$(
  aws elasticache describe-replication-groups \
    --region "$AWS_REGION_NAME" \
    --replication-group-id togglemaster-homolog-redis \
    --query 'ReplicationGroups[0].NodeGroups[0].PrimaryEndpoint.Port' \
    --output text
)"

SQS_URL="$(
  aws sqs get-queue-url \
    --region "$AWS_REGION_NAME" \
    --queue-name togglemaster-analytics \
    --query 'QueueUrl' \
    --output text
)"

export REDIS_URL="redis://${REDIS_HOST}:${REDIS_PORT}"
export SQS_URL

python3 - <<'PY'
import os
from pathlib import Path

replacements = {
    "gitops/services/evaluation/deployment.yaml": {
        "REDIS_URL": os.environ["REDIS_URL"],
        "AWS_SQS_URL": os.environ["SQS_URL"],
    },
    "gitops/services/analytics/deployment.yaml": {
        "AWS_SQS_URL": os.environ["SQS_URL"],
    },
}

for filename, variables in replacements.items():
    path = Path(filename)
    lines = path.read_text().splitlines()

    for index, line in enumerate(lines[:-1]):
        name = line.strip()

        if name.startswith("- name: "):
            variable = name.removeprefix("- name: ")

            if variable in variables:
                indentation = line[:len(line) - len(line.lstrip())] + "  "
                lines[index + 1] = (
                    f'{indentation}value: "{variables[variable]}"'
                )

    path.write_text("\n".join(lines) + "\n")
PY

unset REDIS_URL
unset SQS_URL

for directory in gitops/services/*; do
  kubectl kustomize "$directory" >/dev/null 2>&1 || {
    echo "Manifest inválido: $directory"
    exit 1
  }
done

git diff --check

git add \
  gitops/services/evaluation/deployment.yaml \
  gitops/services/analytics/deployment.yaml

if git diff --cached --quiet; then
  git commit --allow-empty \
    -m "chore: redeploy AWS environment"
else
  git commit \
    -m "chore: synchronize AWS runtime endpoints"
fi

git push origin main

echo
echo "Commit enviado."
echo "Acompanhe CI DevSecOps e CD ECR and GitOps no GitHub Actions."
