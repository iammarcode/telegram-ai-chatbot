#!/usr/bin/env bash

# Stop and remove containers and volumes
docker compose down -v

docker compose up bot-db -d