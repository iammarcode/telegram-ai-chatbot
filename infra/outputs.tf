output "ecr_repository_url" {
  value = aws_ecr_repository.telegram_bot.repository_url
}

output "rds_endpoint" {
  value = aws_db_instance.telegram_bot_db.endpoint
}

output "db_secret_arn" {
  value = aws_db_instance.telegram_bot_db.arn
}

output "telegram_token_secret_arn" {
  value = aws_secretsmanager_secret.telegram_token.arn
}

output "telegram_username_secret_arn" {
  value = aws_secretsmanager_secret.telegram_username.arn
}

output "chatgpt_token_secret_arn" {
  value = aws_secretsmanager_secret.chatgpt_token.arn
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}