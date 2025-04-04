#!/usr/bin/env bash
set -e

# 1.Check and run in the infra folder
if [ ! -d "infra" ]; then
  echo "Error: 'infra' folder not found. Exiting..."
  exit 1
fi
cd infra
echo "1.Valid infra folder"


# 2.Check the required variables in terraform.tfvars
REQUIRED_VARS=(
  "db_username"
  "db_password"
  "chatgpt_token"
  "telegram_token"
  "telegram_username"
)
MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
  if ! grep -q "^${var}[[:space:]]*=" terraform.tfvars; then
    MISSING_VARS+=("${var}")
  fi
done
if [ ${#MISSING_VARS[@]} -ne 0 ]; then
  echo "ERROR: Missing these required variables in terraform.tfvars:"
  printf ' - %s\n' "${MISSING_VARS[@]}"
  exit 1
fi
echo "2.Valid terraform.tfvars file"

echo "3.Initializing Terraform..."
terraform init || {
  echo "ERROR: Terraform initialization failed"
  exit 1
}

echo "4.Generating execution plan..."
terraform plan -out=tfplan || {
  echo "ERROR: Plan generation failed"
  exit 1
}

echo "5.Applying infrastructure changes..."
terraform apply tfplan || {
  echo "ERROR: Infrastructure deployment failed"
  exit 1
}

echo "6.Retrieving deployment outputs..."
terraform output || {
  echo "WARNING: Could not retrieve outputs (some resources may not support outputs)"
}

echo "Infrastructure Deployment Completed Successfully!!!"