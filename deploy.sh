#!/bin/bash
set -e

# Variables
DB_PASSWORD="YourSecurePassword123!"
TELEGRAM_TOKEN="7998784983:AAGwxaHQa0spzx2R606iRCc1F9Hl82RmCNU"
TELEGRAM_USERNAME="marcochow_bot"
CHATGPT_TOKEN="a97fb209-0edc-4de7-bf59-648b7b053adc"
REGION="ap-east-1"

# Restore and Reuse the Existing Secrets
#aws secretsmanager restore-secret --secret-id telegram-bot/db-password
#aws secretsmanager restore-secret --secret-id telegram-bot/telegram-token
#aws secretsmanager restore-secret --secret-id telegram-bot/telegram-username
#aws secretsmanager restore-secret --secret-id telegram-bot/chatgpt-token

# Terraform
cd infra
terraform init
terraform plan -var="db_password=${DB_PASSWORD}" -out=tfplan
terraform apply tfplan

# Get ECR URL
ECR_URL=$(terraform output -raw ecr_repository_url)

# Update Secrets
aws secretsmanager put-secret-value --secret-id telegram-bot/telegram-token --secret-string "${TELEGRAM_TOKEN}" --region ${REGION}
aws secretsmanager put-secret-value --secret-id telegram-bot/telegram-username --secret-string "${TELEGRAM_USERNAME}" --region ${REGION}
aws secretsmanager put-secret-value --secret-id telegram-bot/chatgpt-token --secret-string "${CHATGPT_TOKEN}" --region ${REGION}

# Build and Push Docker Image
cd ..
docker build --target prod -t ${ECR_URL}:prod .
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_URL}
docker push ${ECR_URL}:prod

# Deploy ECS Service
aws ecs update-service --cluster telegram-bot-cluster --service telegram-bot-service --force-new-deployment --region ${REGION}

echo "Deployment complete! Check ECS tasks and CloudWatch logs."