#!/bin/bash

set -euo pipefail

DB_HOST="${DB_HOST:-hadoop-04.uni.innopolis.ru}"
DB_PORT="${DB_PORT:-5432}"
TEAM_ID="${TEAM_ID:-0}"
DB_USER="${DB_USER:-team${TEAM_ID}}"
DB_NAME="${DB_NAME:-${DB_USER}_projectdb}"
PASSWORD_FILE="${PASSWORD_FILE:-secrets/.psql.pass}"
WAREHOUSE_DIR="${WAREHOUSE_DIR:-project/warehouse}"
HDFS_USER_DIR="${HDFS_USER_DIR:-/user/${DB_USER}}"
JDBC_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}"

if [[ ! -f "${PASSWORD_FILE}" ]]; then
  echo "Missing password file: ${PASSWORD_FILE}"
  exit 1
fi

password="$(<"${PASSWORD_FILE}")"
password="${password//$'\n'/}"

hdfs dfs -rm -r -f "${HDFS_USER_DIR}/${WAREHOUSE_DIR}" || true
rm -rf output/sqoop_generated
mkdir -p output/sqoop_generated

sqoop import-all-tables \
  --connect "${JDBC_URL}" \
  --username "${DB_USER}" \
  --password "${password}" \
  --compression-codec=snappy \
  --compress \
  --as-avrodatafile \
  --warehouse-dir="${WAREHOUSE_DIR}" \
  --outdir output/sqoop_generated \
  --m 1

hdfs dfs -get "${HDFS_USER_DIR}/${WAREHOUSE_DIR}"/*/*.avsc output/ 2>/dev/null || true
cp output/sqoop_generated/*.java output/ 2>/dev/null || true

echo "Sqoop import finished. Generated files copied to output/."
