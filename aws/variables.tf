variable "github_org" {
  description = "GitHub organization/user that owns this repo"
  type        = string
  default     = "radhasgrl"
}

variable "github_repo" {
  description = "GitHub repository name (used to scope the OIDC trust policy)"
  type        = string
  default     = "data-ingestion-raw"
}

variable "bucket_name" {
  description = "S3 bucket name for the ingestion demo source files (must be globally unique)"
  type        = string
  default     = "data-ingestion-raw-525218385225"
}

variable "snowflake_iam_user_arn" {
  description = "STORAGE_AWS_IAM_USER_ARN from `DESC INTEGRATION DEV_CUSTOMER_RAW_S3_INTEGRATION` — placeholder until the storage integration is created once (see main.tf comment on aws_iam_role.snowflake_storage_integration)"
  type        = string
  default     = "arn:aws:iam::000000000000:user/placeholder-run-desc-integration-first"
}

variable "snowflake_external_id" {
  description = "STORAGE_AWS_EXTERNAL_ID from `DESC INTEGRATION DEV_CUSTOMER_RAW_S3_INTEGRATION` — placeholder until the storage integration is created once"
  type        = string
  default     = "placeholder-run-desc-integration-first"
}
