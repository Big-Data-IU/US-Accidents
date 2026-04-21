#!/bin/bash

set -euo pipefail

RAW_FILE="data/US_Accidents_March23.csv"

if [[ ! -f "${RAW_FILE}" ]]; then
  echo "Preprocess skipped: ${RAW_FILE} not found yet."
  exit 0
fi

python scripts/preprocess_data.py
