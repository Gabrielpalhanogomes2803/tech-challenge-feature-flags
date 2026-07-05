#!/bin/bash

cd ..

docker compose restart auth-service
docker compose restart flag-service
docker compose restart targeting-service
docker compose restart evaluation-service
docker compose restart analytics-service

sleep 10

docker compose ps
