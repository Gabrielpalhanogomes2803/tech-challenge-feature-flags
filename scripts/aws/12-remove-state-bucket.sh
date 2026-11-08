#!/usr/bin/env bash
# Ultima etapa DESTRUTIVA: apaga versoes do bucket S3 informado EXPLICITAMENTE.
# NAO APAGAR o state ate terraform destroy estar COMPLETO E AUDITADO.
set -Eeuo pipefail
export AWS_PROFILE="${AWS_PROFILE_NAME:-togglemaster}"
export AWS_REGION="${AWS_REGION_NAME:-us-east-1}"
export AWS_DEFAULT_REGION="$AWS_REGION"
EXPECTED_ACCOUNT='966523587984'
[[ "$AWS_REGION" == 'us-east-1' ]] || { echo 'BLOQUEADO: regiao'; exit 2; }
account="$(aws sts get-caller-identity --query Account --output text)"
[[ "$account" == "$EXPECTED_ACCOUNT" ]] || { echo 'BLOQUEADO: conta'; exit 2; }

bucket="${1:-}"
[[ "$bucket" =~ ^[a-z0-9][a-z0-9.-]{8,61}[a-z0-9]$ ]] || { echo 'Uso: script NOME_EXATO_DO_BUCKET_TOGGLEMASTER'; exit 2; }
[[ "$bucket" == *togglemaster* ]] || { echo 'BLOQUEADO: nome do bucket nao contem togglemaster'; exit 2; }

# Protecao adicional: bucket deve ser o que consta no backend local, e ter tags de bootstrap.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
backend="$ROOT/terraform/backend.hcl"
[[ -f "$backend" ]] || { echo 'BLOQUEADO: backend.hcl nao existe'; exit 2; }
configured="$(sed -n 's/^[[:space:]]*bucket[[:space:]]*=[[:space:]]*"\([^"[:space:]]*\)".*/\1/p' "$backend" | head -n 1)"
[[ "$configured" == "$bucket" ]] || { echo 'BLOQUEADO: nome difere do backend.hcl'; exit 2; }
aws s3api head-bucket --bucket "$bucket" >/dev/null
tags="$(aws s3api get-bucket-tagging --bucket "$bucket" --output json)"
printf '%s' "$tags" | python3 -c '
import json,sys
x={t["Key"]:t["Value"] for t in json.load(sys.stdin).get("TagSet",[])}
if x.get("Project")!="ToggleMaster" or x.get("ManagedBy")!="TerraformBootstrap":
 raise SystemExit("BLOQUEADO: tags do bucket nao correspondem ao bootstrap ToggleMaster")
'
location="$(aws s3api get-bucket-location --bucket "$bucket" --query LocationConstraint --output text)"
[[ "$location" == 'None' || "$location" == 'us-east-1' ]] || { echo 'BLOQUEADO: bucket fora da regiao esperada'; exit 2; }

cat <<MESSAGE
ULTIMA ETAPA: EXCLUIR O BUCKET VERSIONADO E SEU STATE TERRAFORM
Conta: $account
Bucket: $bucket
Ao executar, voce perdera o estado historico de Terraform deste projeto.
So execute se terraform destroy terminou e a auditoria nao encontrou recursos do laboratorio.
NAO REUTILIZE este script em outros buckets.
MESSAGE
read -r -p "Digite o nome EXATO do bucket para confirmar: " answer
[[ "$answer" == "$bucket" ]] || { echo 'Cancelado'; exit 0; }
read -r -p 'Digite APAGAR-STATE-DEFINITIVAMENTE: ' answer2
[[ "$answer2" == 'APAGAR-STATE-DEFINITIVAMENTE' ]] || { echo 'Cancelado'; exit 0; }

# A AWS CLI pagina list-object-versions. Apagamos lotes <=1000, repetindo ate esvaziar.
while :; do
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT
  aws s3api list-object-versions --bucket "$bucket" --max-items 1000 --output json |
  python3 -c 'import json,sys; d=json.load(sys.stdin); items=[{"Key":v["Key"],"VersionId":v["VersionId"]} for kind in ("Versions","DeleteMarkers") for v in d.get(kind,[])]; print(json.dumps({"Objects":items[:1000],"Quiet":True}))' > "$tmp"
  count="$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["Objects"]))' "$tmp")"
  if [[ "$count" == 0 ]]; then rm -f "$tmp"; break; fi
  echo "Apagando lote de $count versoes e/ou marcadores..."
  aws s3api delete-objects --bucket "$bucket" --delete "file://$tmp" --output json >/dev/null
  rm -f "$tmp"
done
aws s3api delete-bucket --bucket "$bucket" --region "$AWS_REGION"
echo 'Bucket removido. Verifique manualmente AWS e o inventario final.'
