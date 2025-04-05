REGION="ap-east-1"

# S3
aws s3api create-bucket --bucket ai-chat-bot-terraform-state --region ${REGION} --create-bucket-configuration LocationConstraint=ap-east-1
aws s3api put-bucket-versioning --bucket ai-chat-bot-terraform-state --versioning-configuration Status=Enabled --region ${REGION}
aws s3api put-bucket-encryption --bucket ai-chat-bot-terraform-state --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' --region ${REGION}

aws s3 ls s3://ai-chat-bot-terraform-state --region ${REGION}

#TODO: Dynamodb (locking)