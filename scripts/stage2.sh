#!/bin/bash

set -euo pipefail

HIVE_DB_NAME="${HIVE_DB_NAME:-team31_projectdb}"
HIVE_HOST="${HIVE_HOST:-hadoop-03.uni.innopolis.ru}"
HIVE_PORT="${HIVE_PORT:-10001}"
HIVE_PASSWORD="$(head -n 1 secrets/hive.pass)"

HDFS_USER_DIR="/user/team31"
SQOOP_WAREHOUSE="${HDFS_USER_DIR}/project/warehouse"
HIVE_WAREHOUSE="${HDFS_USER_DIR}/project/hive/warehouse"
AVSC_URL="hdfs:///user/team31/project/warehouse/avsc/us_accidents.avsc"

BEELINE_URL="jdbc:hive2://${HIVE_HOST}:${HIVE_PORT}"

HIVE_CONF=(
  --hiveconf "DB_NAME=${HIVE_DB_NAME}"
  --hiveconf "SQOOP_LOC=${SQOOP_WAREHOUSE}/us_accidents"
  --hiveconf "HIVE_WAREHOUSE_LOC=${HIVE_WAREHOUSE}"
  --hiveconf "AVSC_URL=${AVSC_URL}"
)

run_hql() {
  beeline -u "${BEELINE_URL}" -n "team31" -p "${HIVE_PASSWORD}" "${HIVE_CONF[@]}" -f "$1"
}

export_csv() {
  local table="$1"
  local dest="$2"
  beeline -u "${BEELINE_URL}" -n "team31" -p "${HIVE_PASSWORD}" \
    --outputformat=csv2 \
    -e "SELECT * FROM ${HIVE_DB_NAME}.${table};" \
    > "${dest}" 2>/dev/null
}

mkdir -p output

echo "==> Uploading AVSC schema file to HDFS"
hdfs dfs -mkdir -p "project/warehouse/avsc"
hdfs dfs -rm -f "project/warehouse/avsc/us_accidents.avsc" 2>/dev/null || true
hdfs dfs -put "output/sqoop_generated/us_accidents.avsc" "project/warehouse/avsc/us_accidents.avsc"

echo "==> Creating Hive database"
run_hql hive/create_db.hql

echo "==> Creating external Avro table"
run_hql hive/create_external_table.hql

echo "==> Verifying external table schema"
beeline -u "${BEELINE_URL}" -n "team31" -p "${HIVE_PASSWORD}" \
  -e "DESCRIBE FORMATTED ${HIVE_DB_NAME}.us_accidents;"

echo "==> Creating partitioned + bucketed table and populating it"
run_hql hive/create_partitioned_bucketed_table.hql

echo "==> Verifying partitioned table"
beeline -u "${BEELINE_URL}" -n "team31" -p "${HIVE_PASSWORD}" \
  -e "SELECT state, COUNT(*) FROM ${HIVE_DB_NAME}.us_accidents_part_buck GROUP BY state LIMIT 5;"

echo "==> Dropping unpartitioned external table"
run_hql hive/drop_unpartitioned.hql

echo "==> EDA Q1: Road feature impact on accidents"
run_hql hive/q1.hql
export_csv q1_out output/q1.csv

echo "==> EDA Q2: Accidents by wind speed range"
run_hql hive/q2.hql
export_csv q2_out output/q2.csv

echo "==> EDA Q3: Accidents by visibility range"
run_hql hive/q3.hql
export_csv q3_out output/q3.csv

echo "==> EDA Q4: Top 10 accident cities"
run_hql hive/q4.hql
export_csv q4_out output/q4.csv

echo "==> EDA Q5: Accidents by hour of day"
run_hql hive/q5.hql
export_csv q5_out output/q5.csv

echo "==> EDA Q6: Top weather conditions"
run_hql hive/q6.hql
export_csv q6_out output/q6.csv

echo "==> EDA Q7: Severity distribution"
run_hql hive/q7.hql
export_csv q7_out output/q7.csv

echo "Stage 2 complete. CSV results are in output/."
