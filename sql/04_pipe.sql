-- Manual-trigger pipe (AUTO_INGEST = FALSE) — the demo runs `ALTER PIPE ... REFRESH;`
-- after dropping a file in S3, rather than relying on an S3 event notification -> SQS
-- trigger. Upgrading to full auto-ingest later only requires setting AUTO_INGEST = TRUE
-- here and wiring the resulting notification_channel (see `DESC PIPE`) to an S3 event
-- notification on the bucket — nothing else in this file changes.
CREATE PIPE IF NOT EXISTS DEV_CUSTOMER_DB.RAW.CUSTOMER_INGEST_PIPE
  AUTO_INGEST = FALSE
  COMMENT = 'Manual-trigger Snowpipe — run ALTER PIPE ... REFRESH after uploading a file to S3'
  AS
  COPY INTO DEV_CUSTOMER_DB.RAW.CUSTOMERS
  FROM @DEV_CUSTOMER_DB.RAW.CUSTOMER_RAW_STAGE
  FILE_FORMAT = (FORMAT_NAME = DEV_CUSTOMER_DB.RAW.CUSTOMER_CSV_FORMAT)
  ON_ERROR = 'SKIP_FILE';
