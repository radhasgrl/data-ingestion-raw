# data-ingestion-raw (Repo 2 of 3)

Snowpipe ingestion into the Customer domain's RAW layer — the second repo in the 3-repo
platform demo. Loads CSV files dropped in S3 into `DEV_CUSTOMER_DB.RAW.CUSTOMERS`, a table
owned and defined by Repo 1 (`infra-snowflake`).

```
Repo 1: infra-snowflake (Terraform + DCM)  → provisions DEV_CUSTOMER_DB.RAW.CUSTOMERS,
                                               tiered RBAC, and this repo's own Snowflake
                                               identity (GITHUB_DEV_INGEST_SVC)
Repo 2: data-ingestion-raw (this repo)      → S3 bucket → storage integration → stage →
                                               pipe → DEV_CUSTOMER_DB.RAW.CUSTOMERS
Repo 3: customer-domain-dbt                 → stg_customers -> dim_customers
```

This repo intentionally contains no Terraform/DCM definitions at all — no Snowflake
database objects (databases, schemas, warehouses, RBAC) and no AWS infrastructure (S3
bucket, IAM roles). All resource provisioning for the whole platform lives in Repo 1
(`snowflake-platform-tf`), including the AWS infra this repo's pipeline runs against
(see `ingestion_aws_infra.tf` in Repo 1). This repo owns only ingestion **code**: the SQL
that creates the Snowflake-side ingestion objects (storage integration, stage, file
format, pipe) that load into Repo 1's `RAW.CUSTOMERS` table, plus the CI/CD that runs it.

## Manual-trigger Snowpipe, by design

This demo uses `AUTO_INGEST = FALSE` — you upload a file, then run `ALTER PIPE ... REFRESH`
to load it, rather than relying on an S3 event notification → SQS → Snowpipe auto-trigger.
This is a deliberate reliability choice for a live demo (deterministic, instant, no extra
AWS event-notification wiring to get wrong). Upgrading to full auto-ingest later only needs:
set `AUTO_INGEST = TRUE` in `sql/04_pipe.sql`, then wire the pipe's `notification_channel`
(see `DESC PIPE`) to an S3 Event Notification on the bucket — nothing else changes.

## One-time setup (you must do this once, in order)

### 1. AWS infra (provisioned by Repo 1 — nothing to run here)

The GitHub Actions OIDC IAM role (`data-ingestion-raw-github-oidc`), the S3 source bucket,
and the IAM role Snowflake assumes (`data-ingestion-raw-snowflake-storage-integration`) are
all provisioned by Repo 1's Terraform (`ingestion_aws_infra.tf`), not this repo. This repo
only references those already-created resource names/ARNs in its SQL and CI — it never
creates or destroys AWS infrastructure.

### 2. Deploy the Snowflake objects (CI — automatic on push, or `workflow_dispatch`)

`.github/workflows/deploy-pipe.yml` runs `sql/01_file_format.sql` →
`sql/02_storage_integration.sql` → `sql/03_external_stage.sql` → `sql/04_pipe.sql`, as
`GITHUB_DEV_INGEST_SVC` (least-privilege: only `DEV_CUSTOMER_INGEST_SERVICE_PRSN`,
provisioned by Repo 1).

### 3. Close the storage integration trust loop (one-time, manual)

The storage integration is created in step 2 with a real AWS role ARN, but that AWS role's
*trust policy* (in Repo 1's `ingestion_aws_infra.tf`) was set up directly with the real
Snowflake IAM user ARN/external ID already known at the time of creation — no placeholder
round-trip needed. If the storage integration is ever recreated from scratch, re-run this
check once:

```sql
DESC INTEGRATION DEV_CUSTOMER_RAW_S3_INTEGRATION;
-- confirm STORAGE_AWS_IAM_USER_ARN / STORAGE_AWS_EXTERNAL_ID match the values hardcoded
-- in Repo 1's ingestion_aws_infra.tf trust policy; update there (via PR) if they differ.
```

Without a matching trust policy, the external stage (`sql/03_external_stage.sql`) will
fail to validate and the pipe will not be able to read from S3.

## Running the demo

**Option A — scripted (click a button):** run the `Load Sample Data (demo)` workflow
(`workflow_dispatch`) — uploads `sample-data/customers_sample.csv` to S3, refreshes the
pipe, and prints the row count.

**Option B — live, for the actual demo:**

1. Upload a CSV to the bucket (AWS Console, or CLI: `aws s3 cp sample-data/customers_sample.csv s3://data-ingestion-raw-525218385225/`).
2. In Snowsight (or `snow sql`): `ALTER PIPE DEV_CUSTOMER_DB.RAW.CUSTOMER_INGEST_PIPE REFRESH;`
3. `SELECT * FROM DEV_CUSTOMER_DB.RAW.CUSTOMERS;` — new rows appear.
4. (Optional) Trigger Repo 3's `dbt build` to show the data flow all the way through to `MARTS.dim_customers`.

## Identity and access (provisioned by Repo 1 — nothing to set up here)

| Item | Value | Owned by |
|---|---|---|
| Snowflake user | `GITHUB_DEV_INGEST_SVC` | Terraform (Repo 1, `oidc_service_user.tf`) |
| Role | `DEV_CUSTOMER_INGEST_SERVICE_PRSN` (Tier 1 persona) | DCM (Repo 1, `sources/definitions/roles.sql` + `grants.sql`) |
| Effective access | `CREATE INTEGRATION` (account), `CREATE STAGE/FILE FORMAT/PIPE` + read-write on `DEV_CUSTOMER_DB.RAW`, `USAGE` on `DEV_INGEST_WH` | Via `DEV_CUSTOMER_INGEST_FNCRL` (Tier 2) |
| Auth method | GitHub OIDC workload identity — no stored password, key, or token | — |
| GitHub Environment | `DEV-Ingest` | This repo |
| AWS role (CI) | `data-ingestion-raw-github-oidc` | Terraform (Repo 1, `ingestion_aws_infra.tf`) |
| AWS role (Snowflake) | `data-ingestion-raw-snowflake-storage-integration` | Terraform (Repo 1, `ingestion_aws_infra.tf`) |
| S3 bucket | `data-ingestion-raw-525218385225` | Terraform (Repo 1, `ingestion_aws_infra.tf`) |
