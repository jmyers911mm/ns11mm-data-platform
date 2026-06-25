"""
Clicky (Web Analytics) -> Snowflake Bronze ingestion pipeline
NS11MM Data Platform

Usage:
    python pipeline.py           # incremental (last 24 hours)
    python pipeline.py --full    # full historical load (first run only)
"""

import sys
import requests
from datetime import datetime, timezone, timedelta

from shared.keyvault import secret
from shared.snowflake_client import land_to_bronze, log_run

SOURCE_SYSTEM = "CLICKY"


def authenticate():
    return {
        "site_id": secret("CLICKY-SITE-ID"),
        "sitekey": secret("CLICKY-SITE-KEY"),
        "output":  "json",
    }


def extract(base_params, modified_since=None):
    base = "https://api.clicky.com/api/stats/4"
    date = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%d")
    results = {}

    for stat_type in STAT_TYPES:
        params = {**base_params, "type": stat_type, "date": date, "limit": 1000}
        r = requests.get(base, params=params, timeout=60)
        r.raise_for_status()
        data = r.json()
        if isinstance(data, list) and data:
            items = data[0].get("dates", [{}])[0].get("items", [])
            results[stat_type] = items
            print(f"    {stat_type}: {len(items):,} records")

    return results


STAT_TYPES = ["visitors", "pageviews", "actions", "referrers", "searches", "goals"]


def run(incremental=True):
    mode = "incremental" if incremental else "full load"
    print(f"\n{'='*60}\n{SOURCE_SYSTEM} -- {mode}\n{'='*60}\n")
    extracted_at  = datetime.now(timezone.utc).isoformat()
    base_params   = authenticate()
    for obj_name, records in extract(base_params).items():
        try:
            count = land_to_bronze(records, SOURCE_SYSTEM, obj_name, extracted_at)
            log_run(SOURCE_SYSTEM, obj_name, "success", count)
        except Exception as e:
            print(f"    ERROR on {obj_name}: {e}")
            log_run(SOURCE_SYSTEM, obj_name, "failed", 0, str(e))
    print(f"\nComplete: {datetime.now(timezone.utc).isoformat()}")


if __name__ == "__main__":
    run(incremental="--full" not in sys.argv)
