#!/usr/bin/env bash

set -e

IMAGE_NAME="chat-bot-image"
TAG="latest"
MULTI_PLATFORM="linux/amd64,linux/arm64"

# Clear container and volume
docker compose down -v

# Build app image
docker buildx build --platform ${MULTI_PLATFORM} --target docker -t "${IMAGE_NAME}:${TAG}" --load .

cp .env.docker .env

docker compose up -d

echo "Docker environment started successfully!"