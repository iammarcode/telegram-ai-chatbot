#!/usr/bin/env bash
# infra_destroy.sh

set -e

# Variables
INFRA_DIR="infra"
REGION="ap-east-1"
SECRET_PREFIX="telegram-bot"
S3_BUCKET="ai-chat-bot-terraform-state"
DYNAMODB_TABLE="terraform-locks"

# Check infra directory
[ ! -d "$INFRA_DIR" ] && { 
  echo "ERROR: 'infra' folder not found"; 
  exit 1;
}
cd "$INFRA_DIR"

# Terraform destroy
echo "1. Destroying resources..."
terraform destroy -auto-approve

# Clean local files
echo "2. Cleaning local files..."
rm -rf .terraform* terraform.tfstate* tfplan

# Delete AWS secrets
echo "3. Removing secrets..."
for secret in db-password telegram-token telegram-username chatgpt-token; do
  aws secretsmanager delete-secret \
    --secret-id "${SECRET_PREFIX}/${secret}" \
    --force-delete-without-recovery \
    --region ${REGION} || true
done

# Clean up backend resources (only if everything else succeeded)
echo "4. Cleaning up backend resources..."
aws s3 rm "s3://${S3_BUCKET}/" --recursive --region ${REGION} || true
aws s3api delete-bucket --bucket ${S3_BUCKET} --region ${REGION} || true
aws dynamodb delete-table --table-name ${DYNAMODB_TABLE} --region ${REGION} || true

echo "Cleanup completed."