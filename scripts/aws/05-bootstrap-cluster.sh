#!/usr/bin/env bash

set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

ensure_aws_auth
cd "$PROJECT_ROOT"

kubectl get nodes >/dev/null 2>&1 || {
  echo "O EKS não está acessível."
  echo "Execute primeiro: ./scripts/aws/04-open-eks.sh"
  exit 1
}

echo "Verificando imagens no ECR..."

for repository in \
  togglemaster-auth \
  togglemaster-flag \
  togglemaster-targeting \
  togglemaster-evaluation \
  togglemaster-analytics
do
  count="$(
    aws ecr describe-images \
      --region "$AWS_REGION_NAME" \
      --repository-name "$repository" \
      --query 'length(imageDetails)' \
      --output text
  )"

  if [[ "$count" == "0" ]]; then
    echo "O repositório $repository ainda não possui imagens."
    echo "Aguarde a conclusão do CD ECR and GitOps."
    exit 1
  fi
done

kubectl apply -f gitops/namespace.yaml

echo
echo "Criando Secret de runtime sem exibir seus valores..."

python3 - <<'PY'
import json
import os
import secrets
import subprocess
from urllib.parse import quote

region = os.environ.get("AWS_REGION_NAME", "us-east-1")

databases = {
    "AUTH_DATABASE_URL": (
        "togglemaster-homolog-auth",
        "auth_db",
    ),
    "FLAG_DATABASE_URL": (
        "togglemaster-homolog-flag",
        "flags_db",
    ),
    "TARGETING_DATABASE_URL": (
        "togglemaster-homolog-targeting",
        "targeting_db",
    ),
}

def aws_json(arguments):
    output = subprocess.check_output(
        ["aws", *arguments, "--region", region, "--output", "json"],
        text=True,
    )
    return json.loads(output)

secret_data = {}

for variable, (instance_id, database_name) in databases.items():
    instance = aws_json([
        "rds",
        "describe-db-instances",
        "--db-instance-identifier",
        instance_id,
        "--query",
        "DBInstances[0].{host:Endpoint.Address,port:Endpoint.Port,secret:MasterUserSecret.SecretArn}",
    ])

    credentials = aws_json([
        "secretsmanager",
        "get-secret-value",
        "--secret-id",
        instance["secret"],
        "--query",
        "SecretString",
    ])

    if isinstance(credentials, str):
        credentials = json.loads(credentials)

    username = quote(credentials["username"], safe="")
    password = quote(credentials["password"], safe="")

    secret_data[variable] = (
        f"postgres://{username}:{password}"
        f"@{instance['host']}:{instance['port']}/{database_name}"
        "?sslmode=require"
    )

secret_data["MASTER_KEY"] = secrets.token_urlsafe(48)
secret_data["SERVICE_API_KEY"] = secrets.token_urlsafe(48)

manifest = {
    "apiVersion": "v1",
    "kind": "Secret",
    "metadata": {
        "name": "togglemaster-runtime-secrets",
        "namespace": "togglemaster",
    },
    "type": "Opaque",
    "stringData": secret_data,
}

subprocess.run(
    ["kubectl", "apply", "-f", "-"],
    input=json.dumps(manifest),
    text=True,
    check=True,
)

print("Secret criado com novas credenciais.")
PY

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

API_HASH="$(
  kubectl get secret togglemaster-runtime-secrets \
    --namespace togglemaster \
    -o jsonpath='{.data.SERVICE_API_KEY}' |
  base64 -d |
  sha256sum |
  awk '{print $1}'
)"

awk '
  /-- Chave conhecida apenas para comunicação/ {exit}
  {print}
' auth-service/db/init.sql > "$TEMP_DIR/auth-init.sql"

cat >> "$TEMP_DIR/auth-init.sql" <<EOF_AUTH

INSERT INTO api_keys (name, key_hash, is_active)
VALUES ('evaluation-service-aws', '${API_HASH}', true)
ON CONFLICT (key_hash) DO NOTHING;
EOF_AUTH

kubectl create configmap auth-db-schema \
  --namespace togglemaster \
  --from-file=init.sql="$TEMP_DIR/auth-init.sql" \
  --dry-run=client -o yaml |
kubectl apply -f -

kubectl create configmap flag-db-schema \
  --namespace togglemaster \
  --from-file=init.sql=flag-service/db/init.sql \
  --dry-run=client -o yaml |
kubectl apply -f -

kubectl create configmap targeting-db-schema \
  --namespace togglemaster \
  --from-file=init.sql=targeting-service/db/init.sql \
  --dry-run=client -o yaml |
kubectl apply -f -

kubectl delete jobs \
  auth-db-init \
  flag-db-init \
  targeting-db-init \
  --namespace togglemaster \
  --ignore-not-found

python3 - <<'PY' | kubectl apply -f -
import json

configurations = [
    (
        "auth-db-init",
        "auth-db-schema",
        "AUTH_DATABASE_URL",
    ),
    (
        "flag-db-init",
        "flag-db-schema",
        "FLAG_DATABASE_URL",
    ),
    (
        "targeting-db-init",
        "targeting-db-schema",
        "TARGETING_DATABASE_URL",
    ),
]

items = []

for job_name, configmap_name, secret_key in configurations:
    items.append({
        "apiVersion": "batch/v1",
        "kind": "Job",
        "metadata": {
            "name": job_name,
            "namespace": "togglemaster",
        },
        "spec": {
            "backoffLimit": 2,
            "template": {
                "spec": {
                    "restartPolicy": "Never",
                    "containers": [{
                        "name": "migration",
                        "image": "postgres:16",
                        "command": [
                            "sh",
                            "-c",
                            'psql "$DATABASE_URL" '
                            "-v ON_ERROR_STOP=1 "
                            "-f /sql/init.sql",
                        ],
                        "env": [{
                            "name": "DATABASE_URL",
                            "valueFrom": {
                                "secretKeyRef": {
                                    "name": "togglemaster-runtime-secrets",
                                    "key": secret_key,
                                },
                            },
                        }],
                        "volumeMounts": [{
                            "name": "schema",
                            "mountPath": "/sql",
                            "readOnly": True,
                        }],
                    }],
                    "volumes": [{
                        "name": "schema",
                        "configMap": {
                            "name": configmap_name,
                        },
                    }],
                },
            },
        },
    })

print(json.dumps({
    "apiVersion": "v1",
    "kind": "List",
    "items": items,
}))
PY

kubectl wait \
  --namespace togglemaster \
  --for=condition=Complete \
  job/auth-db-init \
  job/flag-db-init \
  job/targeting-db-init \
  --timeout=10m

kubectl delete jobs \
  auth-db-init \
  flag-db-init \
  targeting-db-init \
  --namespace togglemaster

echo
echo "Instalando Argo CD..."

kubectl create namespace argocd \
  --dry-run=client -o yaml |
kubectl apply -f -

kubectl apply \
  --server-side \
  --force-conflicts \
  --namespace argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.2/manifests/install.yaml

for deployment in \
  argocd-applicationset-controller \
  argocd-dex-server \
  argocd-notifications-controller \
  argocd-redis \
  argocd-repo-server \
  argocd-server
do
  kubectl rollout status \
    --namespace argocd \
    "deployment/$deployment" \
    --timeout=10m
done

kubectl apply -f gitops/argocd/applications.yaml

echo
echo "Aguardando os cinco microsserviços..."

kubectl wait \
  --namespace togglemaster \
  --for=condition=Available \
  deployment/auth-service \
  deployment/flag-service \
  deployment/targeting-service \
  deployment/evaluation-service \
  deployment/analytics-service \
  --timeout=15m

echo
echo "Bootstrap Kubernetes concluído."
