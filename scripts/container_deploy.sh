#!/usr/bin/env bash
# container_deploy.sh

set -ex

# Variables
TAG="latest"
MULTI_PLATFORM="linux/amd64,linux/arm64"
REGION="ap-east-1"
ECR_REPO_NAME="telegram-bot"
CLUSTER_NAME="telegram-bot-cluster"
SERVICE_NAME="telegram-bot-service"

# Get AWS account ID
echo "1. Get AWS account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text) || { 
  echo "ERROR: Failed to get AWS account ID"; 
  exit 1;
}
[ -z "$AWS_ACCOUNT_ID" ] && { 
  echo "ERROR: Empty AWS account ID"; 
  exit 1;
}

# Ensure ECR repository exists
ECR_REPOSITORY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO_NAME}"
echo "2. Checking/creating ECR repository..."
aws ecr describe-repositories --repository-names "${ECR_REPO_NAME}" --region "${REGION}" >/dev/null 2>&1 || {
  echo "ECR repository not found, creating..."
  aws ecr create-repository --repository-name "${ECR_REPO_NAME}" --region "${REGION}" || {
    echo "ERROR: Failed to create ECR repository"; exit 1;
  }
}

# Authenticate with ECR
echo "3. Authenticating with ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin "${ECR_REPOSITORY_URL}"

# Build and push Docker image
echo "4. Building and pushing Docker image..."
docker buildx build \
  --platform ${MULTI_PLATFORM} \
  --target prod \
  -t "${ECR_REPOSITORY_URL}:${TAG}" \
  --push . || {
    echo "ERROR: Build/push failed"; 
    exit 1; 
}

# Trigger ECS update
echo "5. Triggering ECS update..."
aws ecs update-service \
  --cluster ${CLUSTER_NAME} \
  --service ${SERVICE_NAME} \
  --force-new-deployment \
  --region ${REGION} \
  --query 'service.{cluster:clusterArn,status:status,desiredCount:desiredCount}' \
  --output json

echo "Deployment completed."