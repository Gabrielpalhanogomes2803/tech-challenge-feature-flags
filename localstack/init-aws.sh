#!/bin/bash
set -euo pipefail

awslocal sqs create-queue \
  --queue-name togglemaster-analytics

if ! awslocal dynamodb describe-table \
  --table-name ToggleMasterAnalytics >/dev/null 2>&1; then
  awslocal dynamodb create-table \
    --table-name ToggleMasterAnalytics \
    --attribute-definitions AttributeName=event_id,AttributeType=S \
    --key-schema AttributeName=event_id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
fi
