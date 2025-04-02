#!/bin/bash

# Stop all running containers
echo "Stopping all Docker containers..."
docker stop $(docker ps -aq)

# Remove all containers
echo "Removing all Docker containers..."
docker rm $(docker ps -aq)

# Remove all images
#echo "Removing all Docker images..."
#docker rmi -f $(docker images -q)

# Remove all volumes
echo "Removing all Docker volumes..."
docker volume rm $(docker volume ls -q)

# Remove all networks (skip default networks)
echo "Removing all Docker networks..."
docker network ls | grep "bridge\|none\|host" -v | awk '{if(NR>1) print $1}' | xargs docker network rm

echo "Docker cleanup complete."