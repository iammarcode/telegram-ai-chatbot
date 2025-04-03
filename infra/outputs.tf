output "task_definition_parameters" {
  value = {
    task_execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn                = aws_iam_role.ecs_task_role.arn
    db_host                      = aws_db_instance.telegram_bot_db.address
    db_name                      = aws_db_instance.telegram_bot_db.db_name
    db_username                  = var.db_username
    db_password_secret_arn       = aws_secretsmanager_secret.db_password.arn
    telegram_token_secret_arn    = aws_secretsmanager_secret.telegram_token.arn
    telegram_username_secret_arn = aws_secretsmanager_secret.telegram_username.arn
    chatgpt_token_secret_arn     = aws_secretsmanager_secret.chatgpt_token.arn
    aws_region                   = var.aws_region
    image_url                    = "${aws_ecr_repository.telegram_bot.repository_url}:prod"
  }
  sensitive = true
}

output "generated_task_definition_path" {
  value = "${path.module}/../generated-task-definition.json"
}

output "docker_build_commands" {
  value = <<EOT
To build and push Docker images:
1. Build production image:
   docker build --target prod -t ${aws_ecr_repository.telegram_bot.repository_url}:prod .

2. Login to ECR:
   aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.telegram_bot.repository_url}

3. Push to ECR:
   docker push ${aws_ecr_repository.telegram_bot.repository_url}:prod
  EOT
}