#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

mkdir -p "${ROOT_DIR}/data" "${ROOT_DIR}/output" "${ROOT_DIR}/models"

PREFIX="${HDFS_PREFIX:-project}"

ML_ZIP="${ROOT_DIR}/ml_transformers.zip"
rm -f "${ML_ZIP}"
(cd "${ROOT_DIR}/scripts" && zip -qr "${ML_ZIP}" ml)

echo "[Stage III] spark-submit train_ml.py on Yarn"
spark-submit \
  --master yarn \
  --deploy-mode client \
  --py-files "${ML_ZIP}" \
  "${ROOT_DIR}/scripts/train_ml.py"

echo "[Stage III] Pull JSON splits, predictions, metrics, and models from HDFS (${PREFIX})"
hdfs dfs -getmerge "${PREFIX}/data/train" "${ROOT_DIR}/data/train.json"
hdfs dfs -getmerge "${PREFIX}/data/test" "${ROOT_DIR}/data/test.json"

hdfs dfs -getmerge "${PREFIX}/output/model1_predictions" "${ROOT_DIR}/output/model1_predictions.csv"
hdfs dfs -getmerge "${PREFIX}/output/model2_predictions" "${ROOT_DIR}/output/model2_predictions.csv"
hdfs dfs -getmerge "${PREFIX}/output/evaluation" "${ROOT_DIR}/output/evaluation.csv"

rm -rf "${ROOT_DIR}/models/model1" "${ROOT_DIR}/models/model2"
hdfs dfs -get "${PREFIX}/models/model1" "${ROOT_DIR}/models/model1"
hdfs dfs -get "${PREFIX}/models/model2" "${ROOT_DIR}/models/model2"

echo "[Stage III] pylint"
pylint "${ROOT_DIR}/scripts/train_ml.py" "${ROOT_DIR}/scripts/ml/transformers.py"

echo "[Stage III] Done"
