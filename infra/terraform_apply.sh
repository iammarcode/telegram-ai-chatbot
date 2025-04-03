#!/usr/bin/env bash

set -e

terraform init

terraform plan -out=tfplan

terraform apply tfplan

terraform output