USE ${hiveconf:DB_NAME};

CREATE EXTERNAL TABLE IF NOT EXISTS us_accidents
  STORED AS AVRO
  LOCATION '${hiveconf:SQOOP_LOC}'
  TBLPROPERTIES ('avro.schema.url'='${hiveconf:AVSC_URL}');
