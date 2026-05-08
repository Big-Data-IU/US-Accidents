#!/bin/bash

set -euo pipefail

HIVE_DB_NAME="${HIVE_DB_NAME:-team31_projectdb}"
HIVE_HOST="${HIVE_HOST:-hadoop-03.uni.innopolis.ru}"
HIVE_PORT="${HIVE_PORT:-10001}"
HIVE_PASSWORD="$(head -n 1 secrets/hive.pass)"
BEELINE_URL="jdbc:hive2://${HIVE_HOST}:${HIVE_PORT}"

echo "[Stage 4] Starting automation for ML results visualization"

SQL_COMMANDS="
USE ${HIVE_DB_NAME};

DROP TABLE IF EXISTS evaluation_results;
CREATE EXTERNAL TABLE evaluation_results (
  model STRING,
  accuracy STRING,
  f1 STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
   'separatorChar' = ',',
   'quoteChar'     = '\"',
   'escapeChar'    = '\\\\'
)
STORED AS TEXTFILE
LOCATION 'project/output/evaluation'
TBLPROPERTIES ('skip.header.line.count'='1');

DROP TABLE IF EXISTS model1_results;
CREATE EXTERNAL TABLE model1_results (
  label DOUBLE,
  prediction DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
STORED AS TEXTFILE 
LOCATION 'project/output/model1_predictions'
TBLPROPERTIES ('skip.header.line.count'='1');

DROP TABLE IF EXISTS model2_results;
CREATE EXTERNAL TABLE model2_results (
  label DOUBLE,
  prediction DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
STORED AS TEXTFILE 
LOCATION 'project/output/model2_predictions'
TBLPROPERTIES ('skip.header.line.count'='1');

SELECT 'Evaluation sample:', * FROM evaluation_results LIMIT 1;
SELECT 'Predictions sample:', * FROM model1_results LIMIT 1;
"
beeline -u "${BEELINE_URL}" -n "team31" -p "${HIVE_PASSWORD}" -e "${SQL_COMMANDS}"

echo "[Stage 4] Hive tables created successfully."
