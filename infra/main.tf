terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data Sources
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
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "telegram-bot-private-${count.index}"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "telegram-bot-public-${count.index}"
  }
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
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Database
resource "aws_db_subnet_group" "default" {
  name       = "telegram-bot-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  tags = {
    Name = "Telegram Bot DB Subnet Group"
  }
}

resource "aws_security_group" "rds" {
  name        = "telegram-bot-rds-sg"
  description = "Allow inbound MySQL access from ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "telegram_bot_db" {
  identifier             = "telegram-bot-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = "telegram_bot_db"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
  publicly_accessible    = false
}

# ECS
resource "aws_security_group" "ecs" {
  name        = "telegram-bot-ecs-sg"
  description = "Allow inbound HTTP access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "telegram_bot" {
  name                 = "telegram-bot"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "telegram_bot" {
  name = "telegram-bot-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "telegram-bot-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "telegram-bot-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "telegram-bot/db-password"
}

resource "aws_secretsmanager_secret" "telegram_token" {
  name = "telegram-bot/telegram-token"
}

resource "aws_secretsmanager_secret" "telegram_username" {
  name = "telegram-bot/telegram-username"
}

resource "aws_secretsmanager_secret" "chatgpt_token" {
  name = "telegram-bot/chatgpt-token"
}

resource "aws_iam_policy" "secrets_access" {
  name        = "telegram-bot-secrets-access"
  description = "Policy to access Telegram bot secrets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = [
        aws_secretsmanager_secret.telegram_token.arn,
        aws_secretsmanager_secret.telegram_username.arn,
        aws_secretsmanager_secret.chatgpt_token.arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_secrets" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_ecs_task_definition" "telegram_bot" {
  family                   = "telegram-bot"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "telegram-bot-container"
    image     = "${aws_ecr_repository.telegram_bot.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]
    environment = [
      { name = "SPRING_PROFILES_ACTIVE", value = "docker" },
      { name = "DB_HOST", value = aws_db_instance.telegram_bot_db.address },
      { name = "DB_NAME", value = aws_db_instance.telegram_bot_db.db_name },
      { name = "DB_USERNAME", value = var.db_username },
      { name = "CHATGPT_URL", value = "https://genai.hkbu.edu.hk/general/rest" },
      { name = "CHATGPT_MODEL", value = "pt-4-o-mini" },
      { name = "CHATGPT_API_VERSION", value = "2024-05-01-preview" }
    ]
    secrets = [
      {
        name      = "DB_PASSWORD",
        valueFrom = aws_secretsmanager_secret.db_password.arn  # Changed this line
      },
      {
        name      = "TELEGRAM_TOKEN",
        valueFrom = aws_secretsmanager_secret.telegram_token.arn
      },
      {
        name      = "TELEGRAM_USERNAME",
        valueFrom = aws_secretsmanager_secret.telegram_username.arn
      },
      {
        name      = "CHATGPT_TOKEN",
        valueFrom = aws_secretsmanager_secret.chatgpt_token.arn
      }
    ]
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.telegram_bot.name,
        "awslogs-region"        = var.aws_region,
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "telegram_bot" {
  name            = "telegram-bot-service"
  cluster         = aws_ecs_cluster.telegram_bot.id
  task_definition = aws_ecs_task_definition.telegram_bot.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.telegram_bot.name}/${aws_ecs_service.telegram_bot.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70
  }
}

# Logging
resource "aws_cloudwatch_log_group" "telegram_bot" {
  name              = "/ecs/telegram-bot"
  retention_in_days = 30
}