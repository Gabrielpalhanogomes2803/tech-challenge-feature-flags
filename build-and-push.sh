#!/bin/bash
set -e

ACCOUNT_ID="876908012464"
REGION="us-east-1"
ECR="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

SERVICES=(
    auth-service
    flag-service
    targeting-service
    evaluation-service
    analytics-service
)

echo "==========================================="
echo " Build e Push - ToggleMaster"
echo "==========================================="

echo
echo "Realizando login no ECR..."
aws ecr get-login-password --region $REGION | \
docker login \
--username AWS \
--password-stdin $ECR

echo
echo "Login realizado com sucesso!"
echo

for SERVICE in "${SERVICES[@]}"
do
    echo "==========================================="
    echo "Processando: $SERVICE"
    echo "==========================================="

    cd "$SERVICE"

    echo
    echo "[1/3] Build..."
    docker build -t togglemaster/$SERVICE .

    echo
    echo "[2/3] Tag..."
    docker tag togglemaster/$SERVICE:latest \
    $ECR/togglemaster/$SERVICE:latest

    echo
    echo "[3/3] Push..."
    docker push \
    $ECR/togglemaster/$SERVICE:latest

    cd ..

    echo
    echo "✅ $SERVICE concluído!"
    echo
done

echo
echo "==========================================="
echo "TODAS AS IMAGENS FORAM ENVIADAS AO ECR!"
echo "==========================================="
