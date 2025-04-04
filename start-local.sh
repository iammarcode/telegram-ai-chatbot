#!/usr/bin/env bash

set -e

#docker compose down -v

# Start mysql
docker compose up db -d

cp .env.local .env

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
while ! docker exec -i $(docker compose ps -q db) mysqladmin ping -h localhost --silent; do
    sleep 1
done
echo "MySQL is ready!"

# TODO: fix
#./mvnw spring-boot:run -Dspring.profiles.active=local
./mvnw spring-boot:run
