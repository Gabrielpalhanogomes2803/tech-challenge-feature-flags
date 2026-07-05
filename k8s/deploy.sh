#!/bin/bash

set -e

NAMESPACE="togglemaster"

echo "========================================"
echo " Deployando ToggleMaster no EKS"
echo "========================================"

echo
echo "1. Namespace"
kubectl apply -f namespace.yaml

echo
echo "2. ConfigMap"
kubectl apply -f configmap.yaml

echo
echo "3. Secret"
if [ -s secret.yaml ]; then
    kubectl apply -f secret.yaml
else
    echo "Secret vazio - ignorando"
fi

echo
echo "4. Deployments"
kubectl apply -f deployments/

echo
echo "5. Services"
kubectl apply -f services/

echo
echo "Aguardando Pods..."
sleep 10

echo
echo "==============================="
echo "Deployments"
kubectl get deployments -n $NAMESPACE

echo
echo "Pods"
kubectl get pods -n $NAMESPACE -o wide

echo
echo "Services"
kubectl get svc -n $NAMESPACE

echo
echo "Fim."
