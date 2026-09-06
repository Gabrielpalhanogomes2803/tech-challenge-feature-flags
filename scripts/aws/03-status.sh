#!/usr/bin/env bash

set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

ensure_aws_auth

echo
echo "=== EKS ==="
aws eks list-clusters \
  --region "$AWS_REGION_NAME" \
  --query 'clusters'

echo
echo "=== RDS ==="
aws rds describe-db-instances \
  --region "$AWS_REGION_NAME" \
  --query 'DBInstances[].{Name:DBInstanceIdentifier,Status:DBInstanceStatus}'

echo
echo "=== REDIS ==="
aws elasticache describe-replication-groups \
  --region "$AWS_REGION_NAME" \
  --query 'ReplicationGroups[].{Name:ReplicationGroupId,Status:Status}'

echo
echo "=== ECR ==="
aws ecr describe-repositories \
  --region "$AWS_REGION_NAME" \
  --query 'repositories[].repositoryName'

echo
echo "=== DYNAMODB ==="
aws dynamodb list-tables \
  --region "$AWS_REGION_NAME" \
  --query 'TableNames'

echo
echo "=== SQS ==="
aws sqs list-queues \
  --region "$AWS_REGION_NAME" \
  --query 'QueueUrls'
