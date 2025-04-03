#!/usr/bin/env bash

# Exit on any error
set -e

# Check if AWS CLI is configured and get the account ID
if ! AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text); then
  echo "Error: Failed to retrieve AWS account ID. Ensure AWS CLI is configured with valid credentials."
  exit 1
fi

# Ensure account ID is not empty
if [ -z "$AWS_ACCOUNT_ID" ]; then
  echo "Error: AWS account ID is empty. Check AWS CLI configuration."
  exit 1
fi

# Set ECR_REPOSITORY_URL using the dynamically retrieved account ID
ECR_REPOSITORY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.ap-east-1.amazonaws.com/telegram-bot"

# Build the Java Application
./mvnw clean package

# Build the Docker Image
docker build --target prod -t "${ECR_REPOSITORY_URL}:prod" .

# Log in to AWS ECR
aws ecr get-login-password --region ap-east-1 | docker login --username AWS --password-stdin "${ECR_REPOSITORY_URL}"

# Push the Docker Image
docker push "${ECR_REPOSITORY_URL}:prod"

# Force a New Deployment (If the ECS service doesn’t automatically pick up the new image)
aws ecs update-service --cluster telegram-bot-cluster --service telegram-bot-service --force-new-deployment --region ap-east-1

# Verify the Service
aws ecs describe-services --cluster telegram-bot-cluster --services telegram-bot-service --region ap-east-1

# Check Logs
aws logs tail /ecs/telegram-bot --region ap-east-1