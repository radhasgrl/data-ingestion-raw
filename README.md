# data-ingestion-raw (Repo 2 of 3)

Snowpipe ingestion into per-domain RAW layers — the second repo in the 3-repo platform
demo. Currently loads CSV files dropped in S3 into `DEV_CUSTOMER_DB.RAW.CUSTOMERS`, a table
owned and defined by Repo 1 (`snowflake-platform-tf`). This repo stays **one shared repo**
across every domain that uses the Snowpipe ingestion pattern (unlike Repo 3, which is one
repo per domain) — what's per-domain here is the SQL template's rendered values and each
domain's own CI gating, not the repo itself.

```
Repo 1: snowflake-platform-tf (Terraform + DCM) → provisions DEV_CUSTOMER_DB.RAW.CUSTOMERS,
                                                    tiered RBAC, and this repo's own Snowflake
                                                    identities (GITHUB_DEV_INGEST_SVC, per domain)
Repo 2: data-ingestion-raw (this repo)           → S3 bucket → storage integration → stage →
                                                    pipe → DEV_CUSTOMER_DB.RAW.CUSTOMERS
Repo 3: customer-domain-dbt                      → stg_customers -> dim_customers
```

This repo intentionally contains no Terraform/DCM definitions at all — no Snowflake
database objects (databases, schemas, warehouses, RBAC) and no AWS infrastructure (S3
bucket, IAM roles). All resource provisioning for the whole platform lives in Repo 1
(`snowflake-platform-tf`), including the AWS infra this repo's pipeline runs against
(see `ingestion_aws_infra.tf` in Repo 1). This repo owns only ingestion **code**: the SQL
that creates the Snowflake-side ingestion objects (storage integration, stage, file
format, pipe) that load into Repo 1's `RAW` tables, plus the CI/CD that runs it.

## Folder structure

```
.
├── patterns/
│   ├── snowpipe/                     # THE canonical, domain-agnostic Snowpipe-pattern
│   │   ├── sql/
│   │   │   ├── 01_file_format.sql    #   template — Jinja2-templated, zero hardcoded
│   │   │   ├── 02_storage_integration.sql # domain names. Rendered via
│   │   │   ├── 03_external_stage.sql #   `snow sql --enable-templating JINJA`, not a
│   │   │   └── 04_pipe.sql           #   custom synthesis script (Repo 1 needs one
│   │   │                            #   because DCM owns that mechanism itself; the
│   │   │                            #   Snowflake CLI's own templating does it here).
│   │   └── active_domains.json       # The "go live" switch for THIS pattern — only
│   │                                 #   domains listed here ever get a
│   │                                 #   deploy-snowpipe.yml CI job
│   ├── openflow/                     # Reserved, dormant pattern — proves the "one
│   │   ├── README.md                 #   workflow per pattern" structure generalizes.
│   │   └── active_domains.json       #   Empty ([]) — deploy-openflow.yml never runs.
│   └── api/                          # Same as openflow/, for a custom API-poller pattern.
│       ├── README.md
│       └── active_domains.json       # Empty ([])
│
├── sources/
│   └── customer/
│       └── snowpipe-params.yml       # Customer's own values for the Snowpipe pattern —
│                                     #   database, table, stage/pipe/integration names,
│                                     #   bucket prefix, identity. Zero SQL.
│
├── detect-changed-domains.sh         # diffs changed files -> which active domains' deploy
│                                     #   jobs should run, per pattern (shared by all 3
│                                     #   deploy-*.yml workflows, not duplicated per pattern)
│
├── .github/workflows/
│   ├── deploy-snowpipe.yml           # detect-domains + matrix deploy job (one per changed
│   │                                 #   active domain), on push to main or workflow_dispatch
│   ├── deploy-openflow.yml           # same shape, dormant (patterns/openflow/active_domains.json is empty)
│   ├── deploy-api.yml                # same shape, dormant (patterns/api/active_domains.json is empty)
│   ├── validate-pipe.yml             # sqlfluff lint of patterns/snowpipe/sql/ + diff preview, on PR
│   ├── load-sample-data.yml          # workflow_dispatch, domain input — demo helper
│   └── reset-demo-data.yml           # workflow_dispatch, domain input — demo helper
│
├── sample-data/customers_sample.csv
└── README.md
```

## Onboarding a new ingestion domain

Same discipline as Repo 1's domain templating — a new domain using the **Snowpipe pattern**
needs zero new SQL:

1. Write `sources/<domain>/snowpipe-params.yml` (copy Customer's, change the values —
   database, table, stage/pipe/integration names, `bucket_prefix`, identity/role/warehouse).
2. Add `{"name": "<domain>", "target": "<DOMAIN>", "github_environment": "DEV-Ingest-<Domain>"}`
   to `patterns/snowpipe/active_domains.json`.
3. Create that domain's `GITHUB_DEV_<DOMAIN>_INGEST_SVC` identity and `DEV-Ingest-<Domain>`
   GitHub Environment (see Repo 1's `terraform/domains.yaml` and this repo's
   "Identity and access" section below).
4. Merge. `deploy-snowpipe.yml`'s detect-domains job picks up the new domain automatically.

A **different ingestion pattern** gets its own sibling folder (`patterns/<pattern>/`) and
workflow (`deploy-<pattern>.yml`) — not a bigger version of this one. `patterns/openflow/`
and `patterns/api/` already exist as dormant, ready-to-use examples of this (see their own
READMEs for the exact activation steps) — proving the structure generalizes without
fabricating fake Openflow/API functionality that doesn't exist yet. This repo stays
organized by pattern, same as the user's original request: "repo 2 will have = ingestion
pattern based" workflows.

## Manual-trigger Snowpipe, by design

This demo uses `AUTO_INGEST = FALSE` — you upload a file, then run `ALTER PIPE ... REFRESH`
to load it, rather than relying on an S3 event notification → SQS → Snowpipe auto-trigger.
This is a deliberate reliability choice for a live demo (deterministic, instant, no extra
AWS event-notification wiring to get wrong). Upgrading to full auto-ingest later only needs:
set `AUTO_INGEST = TRUE` in `patterns/snowpipe/sql/04_pipe.sql`, then wire the pipe's
`notification_channel` (see `DESC PIPE`) to an S3 Event Notification on the bucket —
nothing else changes, and the change applies to every domain using this pattern at once.

## One-time setup (you must do this once, in order)

### 1. AWS infra (provisioned by Repo 1 — nothing to run here)

The GitHub Actions OIDC IAM role (`data-ingestion-raw-github-oidc`), the S3 source bucket,
and the IAM role Snowflake assumes (`data-ingestion-raw-snowflake-storage-integration`) are
all provisioned by Repo 1's Terraform (`ingestion_aws_infra.tf`), not this repo. This repo
only references those already-created resource names/ARNs in its SQL and CI — it never
creates or destroys AWS infrastructure. The bucket is shared across every domain using this
pattern; what's per-domain is the prefix within it (`bucket_prefix` in each domain's
`snowpipe-params.yml`).

### 2. Deploy the Snowflake objects (CI — automatic on push, or `workflow_dispatch`)

`.github/workflows/deploy-snowpipe.yml` renders `patterns/snowpipe/sql/01_file_format.sql` →
`02_storage_integration.sql` → `03_external_stage.sql` → `04_pipe.sql` for each changed
active domain, as that domain's own ingestion identity (`GITHUB_DEV_INGEST_SVC` for
Customer — least-privilege: only `DEV_CUSTOMER_INGEST_SERVICE_PRSN`, provisioned by Repo 1).

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

Without a matching trust policy, the external stage will fail to validate and the pipe
will not be able to read from S3.

## Running the demo

**Option A — scripted (click a button):** run the `Load Sample Data (demo)` workflow
(`workflow_dispatch`, `domain` input defaults to `customer`) — uploads
`sample-data/customers_sample.csv` to S3, refreshes the pipe, and prints the row count.

**Option B — live, for the actual demo:**

1. Upload a CSV to the bucket (AWS Console, or CLI: `aws s3 cp sample-data/customers_sample.csv s3://data-ingestion-raw-525218385225/`).
2. In Snowsight (or `snow sql`): `ALTER PIPE DEV_CUSTOMER_DB.RAW.CUSTOMER_INGEST_PIPE REFRESH;`
3. `SELECT * FROM DEV_CUSTOMER_DB.RAW.CUSTOMERS;` — new rows appear.
4. (Optional) Trigger Repo 3's `dbt build` to show the data flow all the way through to `MARTS.dim_customers`.

## Identity and access (provisioned by Repo 1 — nothing to set up here)

| Item | Value | Owned by |
|---|---|---|
| Snowflake user | `GITHUB_DEV_INGEST_SVC` | Terraform (Repo 1, `terraform/modules/domain_onboarding/` + `terraform/domains.yaml`) |
| Role | `DEV_CUSTOMER_INGEST_SERVICE_PRSN` (Tier 1 persona) | DCM (Repo 1, `dcm/sources/definitions/roles.sql` + `grants.sql`) |
| Effective access | `CREATE INTEGRATION` (account), `CREATE STAGE/FILE FORMAT/PIPE` + read-write on `DEV_CUSTOMER_DB.RAW`, `USAGE` on `DEV_CUSTOMER_INGEST_WH` | Via `DEV_CUSTOMER_INGEST_FNCRL` (Tier 2) |
| Auth method | GitHub OIDC workload identity — no stored password, key, or token | — |
| GitHub Environment | `DEV-Ingest` (Customer kept its original unprefixed name; later domains use `DEV-Ingest-<Domain>`) | This repo |
| AWS role (CI) | `data-ingestion-raw-github-oidc` | Terraform (Repo 1, `ingestion_aws_infra.tf`) |
| AWS role (Snowflake) | `data-ingestion-raw-snowflake-storage-integration` | Terraform (Repo 1, `ingestion_aws_infra.tf`) |
| S3 bucket | `data-ingestion-raw-525218385225` (shared across domains, prefix-scoped per domain) | Terraform (Repo 1, `ingestion_aws_infra.tf`) |

## Environments & Versioning

| Environment | How it's reached | Snowflake objects (Customer) | GitHub Environment | Approval gate |
|---|---|---|---|---|
| DEV | Automatic — every merge to `main` | `DEV_CUSTOMER_DB`, `DEV_CUSTOMER_INGEST_WH`, `DEV_CUSTOMER_INGEST_SERVICE_PRSN` | `DEV-Ingest` | None (continuous) |
| TEST | Manual — `promote.yml` dispatched against a specific release tag | `TEST_CUSTOMER_DB`, TEST-distinct stage/pipe/file-format/integration names (see `sources/customer/snowpipe-params-test.yml`) | `TEST-Ingest` | Required reviewer, non-bypassable even by an admin |
| PROD | Not built yet | — | — | — |

Same pattern as Repo 1 (`snowflake-platform-tf`) — see that repo's README for the full
mechanics:
- PR titles must follow Conventional Commits (`pr-title-lint.yml`, required check) — this
  repo squash-merges, so the title becomes `main`'s commit message, which
  `release-please` reads to compute version bumps.
- `release-please.yml` maintains one standing Release PR; merging it is the deliberate
  "cut a release" action that creates the real tag + GitHub Release.
- `promote.yml` (`workflow_dispatch`-only) checks out the exact tagged release — not
  whatever `main` currently is — and deploys Customer's Snowpipe objects (file format,
  storage integration, external stage, pipe) into TEST using genuinely distinct object
  names from DEV's (not just a different database), so `CREATE ... IF NOT EXISTS`
  statements never silently no-op against DEV's already-existing objects.

