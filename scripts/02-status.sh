#!/bin/bash

cd ..

echo "=============================="
echo "Docker Compose"
echo "=============================="

docker compose ps

echo
echo "=============================="
echo "Containers"
echo "=============================="

docker ps
