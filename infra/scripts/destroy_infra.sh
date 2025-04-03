#!/usr/bin/env bash

set -e

# Destroy Terraform resources
echo "1. Destroying Terraform resources..."
terraform destroy -auto-approve

# Remove local files
echo "2. Removing local Terraform files..."
rm -rf \
  .terraform* \
  terraform.tfstate* \
  tfplan

# Delete AWS secrets
echo "3. Cleaning up AWS secrets..."
aws secretsmanager delete-secret --secret-id telegram-bot/db-password --force-delete-without-recovery --region ap-east-1
aws secretsmanager delete-secret --secret-id telegram-bot/telegram-token --force-delete-without-recovery --region ap-east-1
aws secretsmanager delete-secret --secret-id telegram-bot/telegram-username --force-delete-without-recovery --region ap-east-1
aws secretsmanager delete-secret --secret-id telegram-bot/chatgpt-token --force-delete-without-recovery --region ap-east-1