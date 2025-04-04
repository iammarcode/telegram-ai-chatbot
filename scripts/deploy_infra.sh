#!/usr/bin/env bash
set -e

# Check and rn in the infra folder
if [ ! -d "infra" ]; then
  echo "Error: 'infra' folder not found. Exiting..."
  exit 1
fi
cd infra

echo "Infrastructure Deployment Started"

echo "1.Initializing Terraform..."
terraform init || {
  echo "ERROR: Terraform initialization failed"
  exit 1
}

echo "2.Generating execution plan..."
terraform plan -out=tfplan || {
  echo "ERROR: Plan generation failed"
  exit 1
}

echo "3.Applying infrastructure changes..."
terraform apply tfplan || {
  echo "ERROR: Infrastructure deployment failed"
  exit 1
}

echo "4.Retrieving deployment outputs..."
terraform output || {
  echo "WARNING: Could not retrieve outputs (some resources may not support outputs)"
}

echo "Infrastructure Deployment Completed Successfully"