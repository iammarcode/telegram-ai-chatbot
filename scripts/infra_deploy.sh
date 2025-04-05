#!/usr/bin/env bash
# infra_deploy.sh

set -e

# Variables
INFRA_DIR="infra"
REQUIRED_VARS=(
  "db_username"
  "db_password"
  "chatgpt_token"
  "telegram_token"
  "telegram_username"
)

# Check infra directory
[ ! -d "$INFRA_DIR" ] && { 
  echo "ERROR: 'infra' folder not found"; 
  exit 1; 
}
cd "$INFRA_DIR"
echo "1. Entered infra directory"

# Check required variables
MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
  grep -q "^${var}[[:space:]]*=" terraform.tfvars || MISSING_VARS+=("${var}")
done
[ ${#MISSING_VARS[@]} -ne 0 ] && { 
  echo "ERROR: Missing variables in terraform.tfvars:"
  printf ' - %s\n' "${MISSING_VARS[@]}"
  exit 1
}
echo "2. Valid terraform.tfvars"

# Terraform operations
echo "3. Initializing Terraform..."
terraform init || { 
  echo "ERROR: Terraform init failed"; 
  exit 1; 
}

echo "4. Generating execution plan..."
terraform plan -out=tfplan || { 
  echo "ERROR: Plan generation failed"; 
  exit 1; 
}

echo "5. Applying changes..."
terraform apply -auto-approve tfplan || { 
  echo "ERROR: Apply failed"; 
  exit 1; 
}

echo "6. Retrieving outputs..."
terraform output || echo "WARNING: Could not retrieve all outputs"

echo "Infrastructure deployed successfully."