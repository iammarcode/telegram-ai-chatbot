variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-east-1"
  validation {
    condition = contains([
      "ap-east-1", # Hong Kong
      "us-east-1", # N. Virginia
      "us-west-2", # Oregon
      "eu-west-1", # Ireland
      "ap-southeast-1" # Singapore
    ], var.aws_region)
    error_message = "Invalid AWS Region specified. Supported regions: ap-east-1, us-east-1, us-west-2, eu-west-1, ap-southeast-1."
  }
}

variable "db_username" {
  description = "Database administrator username (MySQL compatible)"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_username) >= 4 && length(var.db_username) <= 16
    error_message = "DB username must be between 4 and 16 characters."
  }
}

variable "db_password" {
  description = "Database administrator password (8-41 chars, must contain 3 of: uppercase, lowercase, numbers, special chars except /@\" )"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_password) >= 8 && length(var.db_password) <= 41
    error_message = "Password must be between 8 and 41 characters."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC (e.g., 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\\/([1-2][0-9]|3[0-2]|[0-9]))$", var.vpc_cidr))
    error_message = "Must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets (minimum 2 for high availability)"
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
  validation {
    condition     = length(var.private_subnets) >= 2
    error_message = "At least 2 private subnets required for HA."
  }
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (minimum 2 for high availability)"
  type = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
  validation {
    condition     = length(var.public_subnets) >= 2
    error_message = "At least 2 public subnets required for HA."
  }
}

variable "db_instance_class" {
  description = "RDS instance class (db.t3.micro for dev, db.t3.medium for prod)"
  type        = string
  default     = "db.t3.micro"
  validation {
    condition = can(regex("^db\\.[t3|r6][a-z]+\\.\\w+$", var.db_instance_class))
    error_message = "Must be a valid RDS instance class (e.g., db.t3.micro)."
  }
}

variable "ecs_task_cpu" {
  description = "ECS task CPU units (1024 units = 1 vCPU)"
  type        = number
  default     = 256
  validation {
    condition = contains([256, 512, 1024, 2048, 4096], var.ecs_task_cpu)
    error_message = "Must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "ecs_task_memory" {
  description = "ECS task memory in MiB (1024 MiB = 1 GB)"
  type        = number
  default     = 512
  validation {
    condition = contains([512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192], var.ecs_task_memory)
    error_message = "Must be one of: 512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192."
  }
}

variable "environment" {
  description = "Deployment environment (dev/stage/prod)"
  type        = string
  default     = "dev"
  validation {
    condition = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stage, prod."
  }
}

variable "tags" {
  description = "Common tags for all resources"
  type = map(string)
  default = {
    Project     = "TelegramBot"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}
