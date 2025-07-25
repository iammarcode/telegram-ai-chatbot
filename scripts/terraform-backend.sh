REGION="ap-east-1"

# S3
aws s3api create-bucket --bucket telegram-ai-chatbot-terraform-state --region ${REGION} --create-bucket-configuration LocationConstraint=ap-east-1
aws s3api put-bucket-versioning --bucket telegram-ai-chatbot-terraform-state --versioning-configuration Status=Enabled --region ${REGION}
aws s3api put-bucket-encryption --bucket telegram-ai-chatbot-terraform-state --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' --region ${REGION}

aws s3 ls s3://telegram-ai-chatbot-terraform-state --region ${REGION}

#TODO: Dynamodb (locking)