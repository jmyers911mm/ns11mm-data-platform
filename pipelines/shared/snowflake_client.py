"""
Snowflake client — shared across all NS11MM pipelines.

Provides:
  - get_connection()      Snowflake connector for direct use
  - land_to_bronze()      Append-only insert of raw JSON records
  - log_run()             Write a row to RAW.PIPELINE_LOG
"""

import json
import os
import snowflake.connector
from datetime import datetime, timezone
from shared.keyvault import secret


def get_connection():
    # Environment is selectable via Function App settings; defaults are dev.
    # Ingestion runs on SOURCES_WH (LOADER_ROLE) per docs/architecture/
    # SNOWFLAKE_SETTINGS.md — COMPUTE_WH is reserved for ad-hoc use.
    return snowflake.connector.connect(
        account   = secret("SNOWFLAKE-ACCOUNT"),
        user      = secret("SNOWFLAKE-USER"),
        password  = secret("SNOWFLAKE-PASSWORD"),
        warehouse = os.environ.get("NS11MM_SNOWFLAKE_WAREHOUSE", "SOURCES_WH"),
        database  = os.environ.get("NS11MM_SNOWFLAKE_DATABASE", "NS11MM_DW_PROD"),
        schema    = "RAW",
        role      = "LOADER_ROLE",
    )


def land_to_bronze(records, source_system, source_object, extracted_at):
    """
    Write raw records to Snowflake Bronze as VARIANT (JSON) rows.
    Append-only — never updates or deletes. Bronze is immutable.
    """
    if not records:
        print(f"    [{source_system}] {source_object}: no records to land.")
        return 0

    table = f"RAW_{source_system}_{source_object.upper()}"
    conn  = get_connection()
    cur   = conn.cursor()

    cur.execute(f"""
        CREATE TABLE IF NOT EXISTS RAW.{table} (
            _extracted_at   TIMESTAMP_TZ   NOT NULL,
            _source_system  VARCHAR        NOT NULL,
            _source_object  VARCHAR        NOT NULL,
            _record_id      VARCHAR,
            _raw_data       VARIANT        NOT NULL
        )
    """)

    rows = [
        (
            extracted_at,
            source_system,
            source_object,
            record.get("id") or record.get("Id") or record.get("ID"),
            json.dumps(record),
        )
        for record in records
    ]

    cur.executemany(
        f"""
        INSERT INTO RAW.{table}
            (_extracted_at, _source_system, _source_object, _record_id, _raw_data)
        VALUES (%s, %s, %s, %s, PARSE_JSON(%s))
        """,
        rows,
    )

    conn.commit()
    cur.close()
    conn.close()
    print(f"    [{source_system}] {source_object}: {len(rows):,} rows -> RAW.{table}")
    return len(rows)


def log_run(source_system, source_object, status, record_count, error_message=None):
    """Write a pipeline run record to RAW.PIPELINE_LOG."""
    conn = get_connection()
    cur  = conn.cursor()

    cur.execute("""
        CREATE TABLE IF NOT EXISTS RAW.PIPELINE_LOG (
            run_at          TIMESTAMP_TZ   NOT NULL,
            source_system   VARCHAR        NOT NULL,
            source_object   VARCHAR        NOT NULL,
            status          VARCHAR        NOT NULL,
            records_landed  INTEGER,
            error_message   VARCHAR
        )
    """)

    cur.execute(
        """
        INSERT INTO RAW.PIPELINE_LOG
            (run_at, source_system, source_object, status, records_landed, error_message)
        VALUES (%s, %s, %s, %s, %s, %s)
        """,
        (
            datetime.now(timezone.utc).isoformat(),
            source_system, source_object, status, record_count, error_message,
        ),
    )

    conn.commit()
    cur.close()
    conn.close()
