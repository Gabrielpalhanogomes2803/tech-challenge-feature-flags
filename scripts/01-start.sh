#!/bin/bash

echo "========================================"
echo " Subindo ambiente Docker"
echo "========================================"

cd ..

docker compose up -d

echo
echo "Aguardando PostgreSQL iniciar..."
sleep 20

echo
echo "Reiniciando microsserviços..."

docker compose restart auth-service
docker compose restart flag-service
docker compose restart targeting-service
docker compose restart evaluation-service
docker compose restart analytics-service

echo
echo "Aguardando serviços..."
sleep 15

echo
echo "Status dos containers"
docker compose ps
