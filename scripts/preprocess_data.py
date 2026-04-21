"""Clean and profile the Stage 1 US Accidents dataset."""

from pathlib import Path

import pandas as pd


ROOT_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT_DIR / "data"
OUTPUT_DIR = ROOT_DIR / "output"
RAW_FILE = DATA_DIR / "US_Accidents_March23.csv"
CLEAN_FILE = DATA_DIR / "US_Accidents_March23_clean.csv"
QUALITY_REPORT = OUTPUT_DIR / "data_quality_stage1.txt"

CHUNK_SIZE = 200_000
BOOL_COLUMNS = [
    "Amenity",
    "Bump",
    "Crossing",
    "Give_Way",
    "Junction",
    "No_Exit",
    "Railway",
    "Roundabout",
    "Station",
    "Stop",
    "Traffic_Calming",
    "Traffic_Signal",
    "Turning_Loop",
]


def clean_chunk(chunk: pd.DataFrame) -> pd.DataFrame:
    """Apply lightweight cleaning rules to one dataframe chunk."""
    chunk = chunk.applymap(lambda x: x.strip() if isinstance(x, str) else x)

    for column in chunk.columns:
        if chunk[column].dtype == object:
            chunk[column] = chunk[column].replace({"": pd.NA, " ": pd.NA})

    if "ID" in chunk.columns:
        chunk = chunk.drop_duplicates(subset=["ID"], keep="first")

    for column in BOOL_COLUMNS:
        if column in chunk.columns:
            chunk[column] = chunk[column].map(
                {"True": True, "False": False, True: True, False: False}
            )

    lat = pd.to_numeric(chunk["Start_Lat"], errors="coerce")
    lng = pd.to_numeric(chunk["Start_Lng"], errors="coerce")
    valid_coords = lat.between(-90, 90) & lng.between(-180, 180)
    chunk = chunk[valid_coords]

    return chunk


def main() -> None:
    """Generate a cleaned CSV and a simple data quality report."""
    if not RAW_FILE.exists():
        raise FileNotFoundError(f"Raw dataset not found: {RAW_FILE}")

    DATA_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    if CLEAN_FILE.exists():
        CLEAN_FILE.unlink()

    total_rows = 0
    cleaned_rows = 0
    desc_nulls = 0
    city_nulls = 0
    weather_nulls = 0

    header_written = False
    for chunk in pd.read_csv(RAW_FILE, chunksize=CHUNK_SIZE, dtype=str):
        total_rows += len(chunk)
        cleaned = clean_chunk(chunk)
        cleaned_rows += len(cleaned)

        desc_nulls += int(cleaned["Description"].isna().sum())
        city_nulls += int(cleaned["City"].isna().sum())
        weather_nulls += int(cleaned["Weather_Condition"].isna().sum())

        cleaned.to_csv(
            CLEAN_FILE,
            mode="a",
            index=False,
            header=not header_written,
        )
        header_written = True

    removed_rows = total_rows - cleaned_rows
    QUALITY_REPORT.write_text(
        "\n".join(
            [
                "Stage 1 data quality summary",
                f"Raw rows: {total_rows}",
                f"Clean rows: {cleaned_rows}",
                f"Removed rows: {removed_rows}",
                f"NULL Description: {desc_nulls}",
                f"NULL City: {city_nulls}",
                f"NULL Weather_Condition: {weather_nulls}",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    print(f"Clean dataset written to: {CLEAN_FILE}")
    print(f"Data quality report written to: {QUALITY_REPORT}")


if __name__ == "__main__":
    main()
