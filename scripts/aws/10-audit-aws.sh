#!/usr/bin/env bash
# ToggleMaster - auditoria READ ONLY, nao cria nem exclui recursos.
set -Eeuo pipefail
REGION="${AWS_REGION_NAME:-us-east-1}"
PROFILE="${AWS_PROFILE_NAME:-togglemaster}"
ACCOUNT_EXPECTED="966523587984"
export AWS_PROFILE="$PROFILE" AWS_REGION="$REGION" AWS_DEFAULT_REGION="$REGION"

account="$(aws sts get-caller-identity --query Account --output text)"
[[ "$account" == "$ACCOUNT_EXPECTED" && "$REGION" == "us-east-1" ]] || { echo "BLOQUEADO: conta/regiao inesperada" >&2; exit 2; }
echo "AUDITORIA ToggleMaster | Conta: $account | Regiao: $REGION"
fail=0
run() { printf '\n=== %s ===\n' "$1"; shift; if ! "$@"; then echo '[ERRO NA CONSULTA: resultado inconclusivo]' >&2; fail=1; fi; }
run 'EKS' aws eks list-clusters --query 'clusters' --output json
run 'ECR (todos na regiao)' aws ecr describe-repositories --query 'repositories[].repositoryName' --output json
run 'RDS' aws rds describe-db-instances --query 'DBInstances[].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}' --output json
run 'Snapshots RDS manuais' aws rds describe-db-snapshots --snapshot-type manual --query 'DBSnapshots[].DBSnapshotIdentifier' --output json
run 'ElastiCache' aws elasticache describe-replication-groups --query 'ReplicationGroups[].{ID:ReplicationGroupId,Status:Status}' --output json
run 'DynamoDB' aws dynamodb list-tables --query 'TableNames' --output json
run 'SQS' aws sqs list-queues --query 'QueueUrls' --output json
run 'VPCs marcadas ToggleMaster' aws ec2 describe-vpcs --filters Name=tag:Project,Values=ToggleMaster --query 'Vpcs[].VpcId' --output json
run 'NAT Gateways com tag ToggleMaster' aws ec2 describe-nat-gateways --filter Name=tag:Project,Values=ToggleMaster --query 'NatGateways[].{ID:NatGatewayId,State:State}' --output json
run 'EBS com tag ToggleMaster' aws ec2 describe-volumes --filters Name=tag:Project,Values=ToggleMaster --query 'Volumes[].{ID:VolumeId,State:State}' --output json
run 'EBS marcados por cluster EKS' aws ec2 describe-volumes --filters Name=tag:kubernetes.io/cluster/togglemaster-homolog-eks,Values=owned,shared --query 'Volumes[].{ID:VolumeId,State:State}' --output json
run 'Elastic IPs marcados ToggleMaster' aws ec2 describe-addresses --filters Name=tag:Project,Values=ToggleMaster --query 'Addresses[].{Allocation:AllocationId,PublicIP:PublicIp}' --output json
run 'Load Balancers ALB/NLB' aws elbv2 describe-load-balancers --query 'LoadBalancers[].{Name:LoadBalancerName,ARN:LoadBalancerArn}' --output json
run 'CloudWatch Logs com prefixo ToggleMaster' aws logs describe-log-groups --log-group-name-prefix /aws/eks/togglemaster --query 'logGroups[].logGroupName' --output json
run 'Secrets Manager (somente nomes)' aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `togglemaster`)].Name' --output json
run 'Buckets S3 candidatos' aws s3api list-buckets --query 'Buckets[?contains(Name, `togglemaster`)].Name' --output json

if [[ -n "${TOGGLEMASTER_STATE_BUCKET:-}" ]]; then
  run 'Objetos/versoes no bucket explicitamente indicado' aws s3api list-object-versions --bucket "$TOGGLEMASTER_STATE_BUCKET" --query '{Versions:length(Versions),DeleteMarkers:length(DeleteMarkers)}' --output json
fi

echo
if [[ "$fail" == 0 ]]; then
  echo 'Consultas executadas sem erro. Revise TODOS os resultados; listas podem incluir recursos de outros projetos.'
else
  echo 'AUDITORIA INCONCLUSIVA: uma ou mais consultas falharam.' >&2
  exit 1
fi
