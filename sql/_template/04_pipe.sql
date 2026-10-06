-- Manual-trigger pipe (AUTO_INGEST = FALSE) — the demo runs `ALTER PIPE ... REFRESH;`
-- after dropping a file in S3, rather than relying on an S3 event notification -> SQS
-- trigger. Upgrading to full auto-ingest later only requires setting AUTO_INGEST = TRUE
-- here and wiring the resulting notification_channel (see `DESC PIPE`) to an S3 event
-- notification on the bucket — nothing else in this file changes.
CREATE PIPE IF NOT EXISTS {{ database }}.RAW.{{ pipe_name }}
  AUTO_INGEST = FALSE
  COMMENT = 'Manual-trigger Snowpipe — run ALTER PIPE ... REFRESH after uploading a file to S3'
  AS
  COPY INTO {{ database }}.RAW.{{ table }}
  FROM @{{ database }}.RAW.{{ stage_name }}
  FILE_FORMAT = (FORMAT_NAME = {{ database }}.RAW.{{ file_format_name }})
  ON_ERROR = 'SKIP_FILE';
