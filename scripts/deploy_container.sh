#!/usr/bin/env bash

# Exit on any error and show commands
set -ex

# --- Initialization ---
echo "[1/5] Verifying AWS configuration..."

# Check AWS CLI configuration
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ $? -ne 0 ]; then
  echo "ERROR [1/5]: Failed to retrieve AWS account ID"
  exit 1
fi

if [ -z "$AWS_ACCOUNT_ID" ]; then
  echo "ERROR [1/5]: Received empty AWS account ID"
  exit 1
fi

ECR_REPOSITORY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.ap-east-1.amazonaws.com/telegram-bot"

echo "[2/5] Building Docker production image"
docker buildx build --platform linux/amd64 --target prod -t "${ECR_REPOSITORY_URL}:prod" --load .

echo "[3/5] Authenticating with ECR"
aws ecr get-login-password --region ap-east-1 | docker login --username AWS --password-stdin "${ECR_REPOSITORY_URL}"

echo "[4/5] Pushing image to ECR"
docker push "${ECR_REPOSITORY_URL}:prod"
if [ $? -ne 0 ]; then
  echo "ERROR [5/5]: Failed to push image to ECR"
  exit 1
fi

echo "[5/5] Triggering ECS service update"
aws ecs update-service \
  --cluster telegram-bot-cluster \
  --service telegram-bot-service \
  --force-new-deployment \
  --region ap-east-1 \
  --query 'service.{cluster:clusterArn,status:status,desiredCount:desiredCount}' \
  --output json

echo "=== Deployment Completed ==="