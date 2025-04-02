#!/usr/bin/env bash

# Env
cp .env.local .env

# Stop and remove containers and volumes
docker compose down -v

docker compose up bot-db -d