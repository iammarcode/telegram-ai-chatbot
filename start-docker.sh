#!/usr/bin/env bash

docker compose down -v

# Rebuild
# docker-compose build --no-cache

docker compose up -d