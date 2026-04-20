#!/bin/bash

set -euo pipefail

echo "[Stage 1] Collecting dataset"
bash scripts/data_collection.sh

echo "[Stage 1] Building PostgreSQL database"
bash scripts/data_storage.sh

echo "[Stage 1] Importing PostgreSQL tables to HDFS via Sqoop"
bash scripts/import_to_hdfs.sh

echo "[Stage 1] Done"
