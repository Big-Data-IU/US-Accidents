#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${ROOT_DIR}/data"
TARGET_FILE="${DATA_DIR}/US_Accidents_March23.csv"

mkdir -p "${DATA_DIR}"

python - <<'PY'
from pathlib import Path
import shutil

from kaggle.api.kaggle_api_extended import KaggleApi

root = Path.cwd()
data_dir = root / "data"
target = data_dir / "US_Accidents_March23.csv"
data_dir.mkdir(parents=True, exist_ok=True)

tmp = data_dir / "_kaggle_download"
if tmp.exists():
    shutil.rmtree(tmp)
tmp.mkdir(parents=True)

api = KaggleApi()
api.authenticate()
api.dataset_download_files(
    "sobhanmoosavi/us-accidents",
    path=str(tmp),
    unzip=True,
    quiet=False,
)

source = None
for candidate in tmp.rglob("US_Accidents_March23.csv"):
    source = candidate
    break
if source is None:
    raise FileNotFoundError(
        f"Could not find US_Accidents_March23.csv under {tmp}. "
        f"Top-level entries: {list(tmp.iterdir())}"
    )

if target.exists():
    target.unlink()
shutil.move(str(source), str(target))
shutil.rmtree(tmp, ignore_errors=True)

print(f"Dataset downloaded to: {target}")
PY
