#!/usr/bin/env bash

set -e

# Stop and remove containers and volumes
docker compose down -v

# Rebuild
docker-compose build --no-cache

docker compose up -d