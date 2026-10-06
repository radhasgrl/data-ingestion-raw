-- External stage over the ingestion bucket, using the storage integration from 02.
CREATE STAGE IF NOT EXISTS {{ database }}.RAW.{{ stage_name }}
  URL = 's3://data-ingestion-raw-525218385225/{{ bucket_prefix }}'
  STORAGE_INTEGRATION = {{ integration_name }}
  FILE_FORMAT = {{ database }}.RAW.{{ file_format_name }}
  COMMENT = 'Stage over the data-ingestion-raw S3 bucket{{ bucket_prefix_comment }}';
