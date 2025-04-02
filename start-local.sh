#!/usr/bin/env bash

# Stop and remove containers and volumes
docker compose down -v

docker compose up db -d