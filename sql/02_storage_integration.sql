-- Storage integration trusting the AWS IAM role created in aws/main.tf
-- (aws_iam_role.snowflake_storage_integration). The role ARN is deterministic (known
-- immediately from the role name/account), but the trust relationship is two-phase:
--
--   1. Run this file (CREATE STORAGE INTEGRATION doesn't validate the AWS side at
--      creation time, so this succeeds even before the AWS role's trust policy is
--      tightened).
--   2. Run `DESC INTEGRATION DEV_CUSTOMER_RAW_S3_INTEGRATION;` and note
--      STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID.
--   3. Re-apply aws/main.tf with those two values
--      (-var snowflake_iam_user_arn=... -var snowflake_external_id=...) to let Snowflake
--      actually assume the role. Until step 3, the external stage (03) will fail to
--      validate.
--
-- STORAGE_ALLOWED_LOCATIONS is scoped to this one bucket only.
CREATE STORAGE INTEGRATION IF NOT EXISTS DEV_CUSTOMER_RAW_S3_INTEGRATION
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::525218385225:role/data-ingestion-raw-snowflake-storage-integration'
  STORAGE_ALLOWED_LOCATIONS = ('s3://data-ingestion-raw-525218385225/')
  COMMENT = 'Trusts the data-ingestion-raw S3 bucket for Snowpipe into DEV_CUSTOMER_DB.RAW.CUSTOMERS';
