output "bucket_name" {
  description = "Name of the S3 bucket holding Terraform remote state"
  value       = aws_s3_bucket.s3_state.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.s3_state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDb table used for state locking"
  value       = aws_dynamodb_table.locks.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDb table"
  value       = aws_dynamodb_table.locks.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt state and locks"
  value       = aws_kms_key.state.arn
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.state.key_id
}
