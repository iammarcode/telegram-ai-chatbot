# S3
aws s3api create-bucket --bucket ai-chat-bot-terraform-state --region ap-east-1 --create-bucket-configuration LocationConstraint=ap-east-1
aws s3api put-bucket-versioning --bucket ai-chat-bot-terraform-state --versioning-configuration Status=Enabled --region ap-east-1
aws s3api put-bucket-encryption --bucket ai-chat-bot-terraform-state --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' --region ap-east-1

# Dynamodb
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-east-1

aws s3 ls s3://ai-chat-bot-terraform-state --region ap-east-1

aws dynamodb describe-table --table-name terraform-locks --region ap-east-1