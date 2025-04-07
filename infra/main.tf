terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket  = "ai-chat-bot-terraform-state"
    key     = "ai-chatbot/terraform.tfstate"
    region  = "ap-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Networking
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "telegram-bot-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "telegram-bot-igw"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "telegram-bot-private-${count.index}"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "telegram-bot-public-${count.index}"
  }
}

resource "aws_eip" "nat" {
  count = length(var.public_subnets)
  tags = {
    Name = "telegram-bot-nat-${count.index}"
  }
}

resource "aws_nat_gateway" "nat" {
  count = length(var.public_subnets)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name = "telegram-bot-nat-${count.index}"
  }
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "telegram-bot-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = length(var.private_subnets)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = {
    Name = "telegram-bot-private-rt-${count.index}"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Database
resource "aws_db_subnet_group" "default" {
  name       = "telegram-bot-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  tags = {
    Name = "telegram-bot-db-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name        = "telegram-bot-rds-sg"
  description = "Allow inbound MySQL access from ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "telegram-bot-rds-sg"
  }
}

resource "aws_db_instance" "telegram_bot_db" {
  identifier           = "telegram-bot-db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  allocated_storage    = 20
  storage_type         = "gp2"
  db_name              = "telegram_bot_db"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name = aws_db_subnet_group.default.name
  publicly_accessible  = false
  tags = {
    Name = "telegram-bot-db"
  }
}

# ECS
resource "aws_security_group" "ecs" {
  name        = "telegram-bot-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "telegram-bot-ecs-sg"
  }
}

resource "aws_ecr_repository" "telegram_bot" {
  name                 = "telegram-bot"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name = "telegram-bot-ecr"
  }
}

resource "aws_ecs_cluster" "telegram_bot" {
  name = "telegram-bot-cluster"
  tags = {
    Name = "telegram-bot-cluster"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "telegram-bot-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name = "telegram-bot-ecs-task-execution-role"
  }
}

resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = "telegram-bot-ecs-task-execution-policy"
  description = "Policy for ECS task execution role"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_custom_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}

resource "aws_iam_role" "ecs_task_role" {
  name = "telegram-bot-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name = "telegram-bot-ecs-task-role"
  }
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "telegram-bot/db-password"
  recovery_window_in_days = 0
  tags = {
    Name = "telegram-bot-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

resource "aws_secretsmanager_secret" "telegram_token" {
  name                    = "telegram-bot/telegram-token"
  recovery_window_in_days = 0
  tags = {
    Name = "telegram-bot-telegram-token"
  }
}

resource "aws_secretsmanager_secret_version" "telegram_token_version" {
  secret_id     = aws_secretsmanager_secret.telegram_token.id
  secret_string = var.telegram_token
}

resource "aws_secretsmanager_secret" "telegram_username" {
  name                    = "telegram-bot/telegram-username"
  recovery_window_in_days = 0
  tags = {
    Name = "telegram-bot-telegram-username"
  }
}

resource "aws_secretsmanager_secret_version" "telegram_username_version" {
  secret_id     = aws_secretsmanager_secret.telegram_username.id
  secret_string = var.telegram_username
}

resource "aws_secretsmanager_secret" "chatgpt_token" {
  name                    = "telegram-bot/chatgpt-token"
  recovery_window_in_days = 0
  tags = {
    Name = "telegram-bot-chatgpt-token"
  }
}

resource "aws_secretsmanager_secret_version" "chatgpt_token_version" {
  secret_id     = aws_secretsmanager_secret.chatgpt_token.id
  secret_string = var.chatgpt_token
}

resource "aws_iam_policy" "secrets_access" {
  name        = "telegram-bot-secrets-access"
  description = "Policy to access Telegram bot secrets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.db_password.arn,
          aws_secretsmanager_secret.telegram_token.arn,
          aws_secretsmanager_secret.telegram_username.arn,
          aws_secretsmanager_secret.chatgpt_token.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_secrets" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

locals {
  task_definition_values = {
    task_execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn                = aws_iam_role.ecs_task_role.arn
    db_host                      = aws_db_instance.telegram_bot_db.address
    db_port                      = aws_db_instance.telegram_bot_db.port
    db_name                      = aws_db_instance.telegram_bot_db.db_name
    db_username                  = var.db_username
    db_password_secret_arn       = aws_secretsmanager_secret.db_password.arn
    telegram_token_secret_arn    = aws_secretsmanager_secret.telegram_token.arn
    telegram_username_secret_arn = aws_secretsmanager_secret.telegram_username.arn
    chatgpt_token_secret_arn     = aws_secretsmanager_secret.chatgpt_token.arn
    aws_region                   = var.aws_region
    image_url                    = "${aws_ecr_repository.telegram_bot.repository_url}:${var.image_tag}"
  }
}

resource "aws_ecs_task_definition" "telegram_bot" {
  family             = "telegram-bot"
  network_mode       = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                = var.ecs_task_cpu
  memory             = var.ecs_task_memory
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = templatefile("${path.module}/task-definitions.json", local.task_definition_values)
}

resource "aws_ecs_service" "telegram_bot" {
  name            = "telegram-bot-service"
  cluster         = aws_ecs_cluster.telegram_bot.id
  task_definition = aws_ecs_task_definition.telegram_bot.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
}

resource "aws_cloudwatch_log_group" "telegram_bot" {
  name              = "/ecs/telegram-bot"
  retention_in_days = 30
  tags = {
    Name = "telegram-bot-logs"
  }
}