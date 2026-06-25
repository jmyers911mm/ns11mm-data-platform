"""
Gateway Ticketing Galaxy -> Snowflake Bronze ingestion pipeline
NS11MM Data Platform

Runs via self-hosted agent on internal network (not Azure Functions).
Requires pyodbc and ODBC Driver 17 for SQL Server on the agent VM.

Usage:
    python pipeline.py           # incremental (last 24 hours)
    python pipeline.py --full    # full historical load (first run only)
"""

import sys
import pyodbc
from datetime import datetime, timezone, timedelta

from shared.keyvault import secret
from shared.snowflake_client import land_to_bronze, log_run

SOURCE_SYSTEM = "GATEWAY"


def authenticate():
    conn_str = (
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={secret('GATEWAY-SQL-HOST')},{secret('GATEWAY-SQL-PORT')};"
        f"DATABASE={secret('GATEWAY-SQL-DB')};"
        f"UID={secret('GATEWAY-SQL-USER')};"
        f"PWD={secret('GATEWAY-SQL-PASSWORD')};"
    )
    return pyodbc.connect(conn_str)


def extract(conn, modified_since=None):
    results = {}
    cursor  = conn.cursor()

    for table_name, base_query in QUERIES.items():
        query = base_query
        if modified_since:
            query += f" WHERE LastModified >= '{modified_since}'"
        cursor.execute(query)
        columns = [col[0] for col in cursor.description]
        results[table_name] = [dict(zip(columns, row)) for row in cursor.fetchall()]
        print(f"    {table_name}: {len(results[table_name]):,} records")

    conn.close()
    return results


# Confirm exact table names with Kenny / Galaxy documentation before first run
QUERIES = {
    "Transactions":  "SELECT * FROM dbo.Transactions",
    "Reservations":  "SELECT * FROM dbo.Reservations",
    "TicketTypes":   "SELECT * FROM dbo.TicketTypes",
    "Customers":     "SELECT * FROM dbo.Customers",
    "Sessions":      "SELECT * FROM dbo.Sessions",
}


def run(incremental=True):
    mode = "incremental" if incremental else "full load"
    print(f"\n{'='*60}\n{SOURCE_SYSTEM} -- {mode}\n{'='*60}\n")
    modified_since = None
    if incremental:
        modified_since = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
    extracted_at = datetime.now(timezone.utc).isoformat()
    conn = authenticate()
    for obj_name, records in extract(conn, modified_since).items():
        try:
            count = land_to_bronze(records, SOURCE_SYSTEM, obj_name, extracted_at)
            log_run(SOURCE_SYSTEM, obj_name, "success", count)
        except Exception as e:
            print(f"    ERROR on {obj_name}: {e}")
            log_run(SOURCE_SYSTEM, obj_name, "failed", 0, str(e))
    print(f"\nComplete: {datetime.now(timezone.utc).isoformat()}")


if __name__ == "__main__":
    run(incremental="--full" not in sys.argv)
