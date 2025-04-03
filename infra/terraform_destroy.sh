#!/usr/bin/env bash

set -e

terraform destroy

rm -rf \
  .terraform/ \
  .terraform.lock.hcl \
  terraform.tfstate \
  terraform.tfstate.backup \
  .terraform.tfstate.lock.info \
  terraform.tfstate.*.backup \
  generated-task-definition.json \
  tfplan

aws secretsmanager delete-secret --secret-id telegram-bot/db-password --force-delete-without-recovery --region ap-east-1
aws secretsmanager delete-secret --secret-id telegram-bot/telegram-token --force-delete-without-recovery --region ap-east-1
aws secretsmanager delete-secret --secret-id telegram-bot/telegram-username --force-delete-without-recovery --region ap-east-1
aws secretsmanager delete-secret --secret-id telegram-bot/chatgpt-token --force-delete-without-recovery --region ap-east-1