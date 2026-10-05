-- External stage over the ingestion bucket, using the storage integration from 02.
CREATE STAGE IF NOT EXISTS DEV_CUSTOMER_DB.RAW.CUSTOMER_RAW_STAGE
  URL = 's3://data-ingestion-raw-525218385225/'
  STORAGE_INTEGRATION = DEV_CUSTOMER_RAW_S3_INTEGRATION
  FILE_FORMAT = DEV_CUSTOMER_DB.RAW.CUSTOMER_CSV_FORMAT
  COMMENT = 'Stage over the data-ingestion-raw S3 bucket';
