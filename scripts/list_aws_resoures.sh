REGION="ap-east-1"

# ECS
aws ecs list-clusters --region $REGION
aws ecs list-services --region $REGION

# ECR
aws ecr describe-repositories --region $REGION

# RDS
aws rds describe-db-instances --region $REGION

# Secrets Manager
aws secretsmanager list-secrets --region $REGION

# CloudWatch Logs
aws logs describe-log-groups --region $REGION

# IAM
aws iam list-roles --region $REGION