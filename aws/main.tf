# GitHub's OIDC provider is one-per-AWS-account, shared across all repos/projects.
# Repo 1 (snowflake-platform-tf) already created this provider in the same AWS account —
# reference it instead of creating a duplicate (AWS rejects a second provider for the same
# issuer URL).
data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

# Role this repo's GitHub Actions workflows assume via AssumeRoleWithWebIdentity — no
# stored AWS secret required. Scoped to this specific repo only (separate from Repo 1's
# own IAM role, which is scoped to snowflake-platform-tf and can't be reused here).
resource "aws_iam_role" "github_actions_ingestion" {
  name = "data-ingestion-raw-github-oidc"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = data.aws_iam_openid_connect_provider.github_actions.arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}@*/${var.github_repo}@*:*"
          }
        }
      }
    ]
  })
}

# Source bucket for the ingestion demo — CSV files land here and Snowpipe loads them into
# DEV_CUSTOMER_DB.RAW.CUSTOMERS (Repo 1).
resource "aws_s3_bucket" "ingestion_raw" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "ingestion_raw" {
  bucket = aws_s3_bucket.ingestion_raw.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role_policy" "ingestion_bucket_access" {
  name = "ingestion-raw-s3-access"
  role = aws_iam_role.github_actions_ingestion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = aws_s3_bucket.ingestion_raw.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.ingestion_raw.arn}/*"
      }
    ]
  })
}

# Separate IAM role: this is the one Snowflake itself assumes (via STORAGE_AWS_IAM_USER_ARN)
# to read the bucket for Snowpipe/external stages — distinct from the GitHub Actions role
# above, which is for CI/CD to manage AWS resources. Two different trust relationships,
# two different roles, by design.
#
# Two-phase setup, unavoidable with Snowflake storage integrations:
#   1. Apply this with the placeholder snowflake_iam_user_arn/snowflake_external_id defaults
#      below, so the role exists (Snowflake's CREATE STORAGE INTEGRATION doesn't validate
#      the AWS side at creation time).
#   2. Deploy sql/02_storage_integration.sql (Repo 2 CI), then run
#      `DESC INTEGRATION DEV_CUSTOMER_RAW_S3_INTEGRATION;` in Snowflake to get the real
#      STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID.
#   3. Re-apply this with the real values (-var snowflake_iam_user_arn=... -var
#      snowflake_external_id=...) to tighten the trust policy. Until step 3, the role exists
#      but nothing can actually assume it.
resource "aws_iam_role" "snowflake_storage_integration" {
  name = "data-ingestion-raw-snowflake-storage-integration"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.snowflake_iam_user_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.snowflake_external_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "snowflake_storage_integration_access" {
  name = "snowflake-storage-integration-s3-access"
  role = aws_iam_role.snowflake_storage_integration.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource = "${aws_s3_bucket.ingestion_raw.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = aws_s3_bucket.ingestion_raw.arn
      }
    ]
  })
}
