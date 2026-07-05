#!/bin/bash

NAMESPACE="togglemaster"

echo "========================================="
echo "   TECH CHALLENGE - EVIDÊNCIAS"
echo "========================================="

echo ""
echo "===== DATA ====="
date

echo ""
echo "===== CLUSTER ====="
kubectl config current-context

echo ""
echo "===== NODES ====="
kubectl get nodes -o wide

echo ""
echo "===== NAMESPACE ====="
kubectl get ns

echo ""
echo "===== PODS ====="
kubectl get pods -n $NAMESPACE -o wide

echo ""
echo "===== DEPLOYMENTS ====="
kubectl get deployments -n $NAMESPACE

echo ""
echo "===== SERVICES ====="
kubectl get svc -n $NAMESPACE

echo ""
echo "===== ENDPOINTS ====="
kubectl get endpoints -n $NAMESPACE

echo ""
echo "===== CONFIGMAP ====="
kubectl get configmap -n $NAMESPACE

echo ""
echo "===== ECR ====="
aws ecr describe-repositories --output table

echo ""
echo "===== GITHUB ACTIONS ====="
gh run list --limit 5

echo ""
echo "========================================="
echo "        FIM DAS EVIDÊNCIAS"
echo "========================================="
