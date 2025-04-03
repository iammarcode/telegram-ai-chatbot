variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-east-1"
}

variable "db_username" {
  description = "Database administrator username (MySQL compatible)"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database administrator password (8-41 chars, must contain 3 of: uppercase, lowercase, numbers, special chars except /@\")"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_password) >= 8 && length(var.db_password) <= 41
    error_message = "Password must be 8-41 characters long."
  }
}

variable "telegram_token" {
  description = "Telegram bot token"
  type        = string
  sensitive   = true
}

variable "telegram_username" {
  description = "Telegram bot username"
  type        = string
}

variable "chatgpt_token" {
  description = "ChatGPT API token"
  type        = string
  sensitive   = true
}

variable "vpc_cidr" {
  description = "CIDR block for VPC (e.g., 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets (minimum 2 for high availability)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (minimum 2 for high availability)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "db_instance_class" {
  description = "RDS instance class (db.t3.micro for dev, db.t3.medium for prod)"
  type        = string
  default     = "db.t3.micro"
}

variable "ecs_task_cpu" {
  description = "ECS task CPU units (1024 units = 1 vCPU)"
  type        = number
  default     = 256
}

variable "ecs_task_memory" {
  description = "ECS task memory in MiB (1024 MiB = 1 GB)"
  type        = number
  default     = 512
}

variable "environment" {
  description = "Deployment environment (dev/stage/prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "TelegramBot"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}