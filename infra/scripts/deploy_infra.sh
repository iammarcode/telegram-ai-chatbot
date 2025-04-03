#!/usr/bin/env bash
set -e

echo "=== Infrastructure Deployment Started ==="

# Step 1: Initialize Terraform
echo "[1/4] Initializing Terraform..."
terraform init || {
  echo "ERROR: Terraform initialization failed"
  exit 1
}

# Step 2: Generate execution plan
echo "[2/4] Generating execution plan..."
terraform plan -out=tfplan || {
  echo "ERROR: Plan generation failed"
  exit 1
}

# Step 3: Apply changes
echo "[3/4] Applying infrastructure changes..."
terraform apply tfplan || {
  echo "ERROR: Infrastructure deployment failed"
  exit 1
}

# Step 4: Show outputs
echo "[4/4] Retrieving deployment outputs..."
terraform output || {
  echo "WARNING: Could not retrieve outputs (some resources may not support outputs)"
}

echo "=== Infrastructure Deployment Completed Successfully ==="