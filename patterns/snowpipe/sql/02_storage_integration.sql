-- Storage integration trusting the AWS IAM role created in Repo 1's
-- terraform/ingestion_aws_infra.tf (aws_iam_role.snowflake_storage_integration) — this is
-- a shared, account-level AWS role/bucket; what's per-domain is the prefix within that
-- bucket (STORAGE_ALLOWED_LOCATIONS below) and the integration object's own name.
--
-- STORAGE_ALLOWED_LOCATIONS is scoped to this domain's own prefix within the shared bucket
-- (empty prefix = bucket root, which is what the original/first domain, Customer, still
-- uses for backward compatibility with its already-live stage).
CREATE STORAGE INTEGRATION IF NOT EXISTS {{ integration_name }}
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::525218385225:role/data-ingestion-raw-snowflake-storage-integration'
  STORAGE_ALLOWED_LOCATIONS = ('s3://data-ingestion-raw-525218385225/{{ bucket_prefix }}')
  COMMENT = 'Trusts the data-ingestion-raw S3 bucket{{ bucket_prefix_comment }} for Snowpipe into {{ database }}.RAW.{{ table }}';
