#!/usr/bin/env bash

# Exit on any error and show commands
set -ex

# --- Initialization ---
echo "=== Deployment Started ==="
echo "[1/5] Verifying AWS configuration..."

# Check AWS CLI configuration
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ $? -ne 0 ]; then
  echo "ERROR [1/5]: Failed to retrieve AWS account ID"
  echo "Troubleshooting:"
  echo "1. Run 'aws --version' to verify CLI installation"
  echo "2. Run 'aws configure' to set up credentials"
  exit 1
fi

if [ -z "$AWS_ACCOUNT_ID" ]; then
  echo "ERROR [1/5]: Received empty AWS account ID"
  exit 1
fi

echo "SUCCESS [1/5]: AWS Account ID: $AWS_ACCOUNT_ID"

# --- Docker Operations ---
ECR_REPOSITORY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.ap-east-1.amazonaws.com/telegram-bot"

echo "[2/5] Building Docker production image"
docker build --target prod -t "${ECR_REPOSITORY_URL}:prod" .

echo "[3/5] Authenticating with ECR"
aws ecr get-login-password --region ap-east-1 | docker login --username AWS --password-stdin "${ECR_REPOSITORY_URL}"

echo "[4/5] Pushing image to ECR"
docker push "${ECR_REPOSITORY_URL}:prod"

# --- ECS Deployment ---
echo "[5/5] Triggering ECS service update"
DEPLOYMENT_OUTPUT=$(aws ecs update-service \
  --cluster telegram-bot-cluster \
  --service telegram-bot-service \
  --force-new-deployment \
  --region ap-east-1 \
  --query 'service.{cluster:clusterArn,status:status,desiredCount:desiredCount}' \
  --output json)

echo "=== Deployment Completed ==="