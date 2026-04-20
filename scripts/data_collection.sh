#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${ROOT_DIR}/data"
TARGET_FILE="${DATA_DIR}/US_Accidents_March23.csv"

mkdir -p "${DATA_DIR}"

python - <<'PY'
from pathlib import Path
import shutil

import kagglehub

root = Path.cwd()
data_dir = root / "data"
target = data_dir / "US_Accidents_March23.csv"
data_dir.mkdir(parents=True, exist_ok=True)

downloaded_dir = Path(kagglehub.dataset_download("sobhanmoosavi/us-accidents"))
source = downloaded_dir / "US_Accidents_March23.csv"
if not source.exists():
    raise FileNotFoundError(f"Could not find dataset file at: {source}")

shutil.copy2(source, target)
print(f"Dataset downloaded to: {target}")
PY
