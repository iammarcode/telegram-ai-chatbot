#!/usr/bin/env bash

set -e

# Stop and remove containers and volumes
docker compose down -v

docker compose up mysql -d