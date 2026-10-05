-- CSV format for the sample customer data. Deployed by GITHUB_DEV_INGEST_SVC
-- (DEV_CUSTOMER_INGEST_SERVICE_PRSN), which has CREATE FILE FORMAT on DEV_CUSTOMER_DB.RAW
-- (see Repo 1's sources/definitions/grants.sql).
CREATE OR REPLACE FILE FORMAT DEV_CUSTOMER_DB.RAW.CUSTOMER_CSV_FORMAT
  TYPE = CSV
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('', 'NULL')
  EMPTY_FIELD_AS_NULL = TRUE
  COMMENT = 'CSV format for sample customer records landed by data-ingestion-raw';

-- test comment to trigger validate-pipe.yml CI check
