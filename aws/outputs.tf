output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_ingestion.arn
  description = "Set as the role-to-assume in .github/workflows/deploy-pipe.yml"
}

output "bucket_name" {
  value = aws_s3_bucket.ingestion_raw.bucket
}

output "snowflake_storage_integration_role_arn" {
  value       = aws_iam_role.snowflake_storage_integration.arn
  description = "Use this as the STORAGE_AWS_ROLE_ARN in sql/02_storage_integration.sql"
}
