#!/usr/bin/env bash

# Env
cp .env.docker .env

# Stop and remove containers and volumes
docker compose down -v

# Rebuild
docker-compose build --no-cache

docker compose up -d