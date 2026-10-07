-- CSV format for the sample {{ domain_label }} data. Deployed by the domain's ingestion
-- service identity, which has CREATE FILE FORMAT on {{ database }}.RAW (see Repo 1's
-- dcm/sources/definitions/grants.sql). Fully generic: a new ingestion domain
-- needs zero new SQL here, only a new sources/<domain>/snowpipe-params.yml.
CREATE OR REPLACE FILE FORMAT {{ database }}.RAW.{{ file_format_name }}
  TYPE = CSV
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('', 'NULL')
  EMPTY_FIELD_AS_NULL = TRUE
  COMMENT = 'CSV format for sample {{ domain_label }} records landed by data-ingestion-raw';
