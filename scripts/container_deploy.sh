#!/usr/bin/env bash

# Exit on any error and show commands
set -ex

TAG="latest"
MULTI_PLATFORM="linux/amd64,linux/arm64"
REGION="ap-east-1"

echo "1.Verifying AWS configuration"

# Check AWS CLI configuration
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to retrieve AWS account ID"
  exit 1
fi

if [ -z "$AWS_ACCOUNT_ID" ]; then
  echo "ERROR: Received empty AWS account ID"
  exit 1
fi

ECR_REPOSITORY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.ap-east-1.amazonaws.com/telegram-bot"

echo "2.Building Docker production image"
docker buildx build --platform ${MULTI_PLATFORM} --target prod -t "${ECR_REPOSITORY_URL}:${TAG}" --load .

echo "3.Authenticating with ECR"
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin "${ECR_REPOSITORY_URL}"

echo "4.Pushing image to ECR"
docker push "${ECR_REPOSITORY_URL}:${TAG}"
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to push image to ECR"
  exit 1
fi

echo "5.Triggering ECS service update"
aws ecs update-service \
  --cluster telegram-bot-cluster \
  --service telegram-bot-service \
  --force-new-deployment \
  --region ${REGION} \
  --query 'service.{cluster:clusterArn,status:status,desiredCount:desiredCount}' \
  --output json

echo "Deployment Completed."