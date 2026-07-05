#!/bin/bash

ACCOUNT="876908012464"
REGION="us-east-1"
PREFIX="togglemaster"

declare -A PORTS=(
  ["flag-service"]=8002
  ["targeting-service"]=8003
  ["evaluation-service"]=8004
  ["analytics-service"]=8005
)

mkdir -p deployments services

for SERVICE in "${!PORTS[@]}"; do
PORT=${PORTS[$SERVICE]}

cat > deployments/${SERVICE}.yaml <<EOL
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${SERVICE}
  namespace: togglemaster
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${SERVICE}
  template:
    metadata:
      labels:
        app: ${SERVICE}
    spec:
      containers:
      - name: ${SERVICE}
        image: ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/${PREFIX}/${SERVICE}:latest
        imagePullPolicy: Always
        ports:
        - containerPort: ${PORT}
        envFrom:
        - configMapRef:
            name: togglemaster-config
EOL

cat > services/${SERVICE}.yaml <<EOL
apiVersion: v1
kind: Service
metadata:
  name: ${SERVICE}
  namespace: togglemaster
spec:
  selector:
    app: ${SERVICE}
  ports:
  - port: ${PORT}
    targetPort: ${PORT}
  type: ClusterIP
EOL

done

echo "Arquivos criados com sucesso!"
