import os
from pathlib import Path
from pprint import pprint

import psycopg2


ROOT_DIR = Path(__file__).resolve().parents[1]
SQL_DIR = ROOT_DIR / "sql"
RAW_DATA_FILE = ROOT_DIR / "data" / "US_Accidents_March23.csv"
CLEAN_DATA_FILE = ROOT_DIR / "data" / "US_Accidents_March23_clean.csv"
PASSWORD_FILE = Path(os.getenv("PASSWORD_FILE", ROOT_DIR / "secrets" / ".psql.pass"))


def getenv_or_default(name: str, default: str) -> str:
    value = os.getenv(name)
    return value if value else default


def read_password() -> str:
    if not PASSWORD_FILE.exists():
        raise FileNotFoundError(f"Missing password file: {PASSWORD_FILE}")
    return PASSWORD_FILE.read_text(encoding="utf-8").strip()


def build_connection_string(password: str) -> str:
    team_id = getenv_or_default("TEAM_ID", "0")
    db_host = getenv_or_default("DB_HOST", "hadoop-04.uni.innopolis.ru")
    db_port = getenv_or_default("DB_PORT", "5432")
    db_user = getenv_or_default("DB_USER", f"team{team_id}")
    db_name = getenv_or_default("DB_NAME", f"{db_user}_projectdb")
    return (
        f"host={db_host} port={db_port} user={db_user} "
        f"dbname={db_name} password={password}"
    )


def run_sql_file(cursor: "psycopg2.extensions.cursor", sql_path: Path) -> None:
    cursor.execute(sql_path.read_text(encoding="utf-8"))


def load_data(cursor: "psycopg2.extensions.cursor") -> None:
    import_sql = SQL_DIR / "import_data.sql"
    copy_command = import_sql.read_text(encoding="utf-8").strip()
    data_file = CLEAN_DATA_FILE if CLEAN_DATA_FILE.exists() else RAW_DATA_FILE
    with data_file.open("r", encoding="utf-8") as csv_file:
        cursor.copy_expert(copy_command, csv_file)


def run_validation(cursor: "psycopg2.extensions.cursor") -> None:
    test_sql = (SQL_DIR / "test_database.sql").read_text(encoding="utf-8")
    for chunk in test_sql.split(";"):
        lines = []
        for raw_line in chunk.splitlines():
            stripped = raw_line.strip()
            if not stripped or stripped.startswith("--"):
                continue
            lines.append(raw_line)
        statement = "\n".join(lines).strip()
        if not statement:
            continue
        cursor.execute(statement)
        pprint(cursor.fetchall())


def main() -> None:
    if not RAW_DATA_FILE.exists():
        raise FileNotFoundError(f"Dataset file does not exist: {RAW_DATA_FILE}")

    password = read_password()
    conn_string = build_connection_string(password)

    with psycopg2.connect(conn_string) as conn:
        with conn.cursor() as cursor:
            run_sql_file(cursor, SQL_DIR / "create_tables.sql")
            conn.commit()

            load_data(cursor)
            conn.commit()

            run_validation(cursor)


if __name__ == "__main__":
    main()
