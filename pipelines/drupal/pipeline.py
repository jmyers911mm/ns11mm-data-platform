"""
Drupal CMS -> Snowflake Bronze ingestion pipeline
NS11MM Data Platform

Usage:
    python pipeline.py           # incremental (last 24 hours)
    python pipeline.py --full    # full historical load (first run only)

NOTE: Path decision (DB vs JSON:API) must be made and documented as an ADR
      before this pipeline is built out. This skeleton uses the JSON:API path.
      If DB path is chosen, replace authenticate() and extract() with pyodbc pattern
      from gateway/pipeline.py.

NOTE: Populate CONTENT_TYPES list after confirming scope with Anna Kim.
"""

import sys
import requests
from datetime import datetime, timezone, timedelta

from shared.keyvault import secret
from shared.snowflake_client import land_to_bronze, log_run

SOURCE_SYSTEM = "DRUPAL"


def authenticate():
    return {"Authorization": f"Bearer {secret('DRUPAL-API-TOKEN')}"}


def extract(headers, modified_since=None):
    base    = secret("DRUPAL-SITE-URL")
    results = {}

    for content_type in CONTENT_TYPES:
        url     = f"{base}/jsonapi/node/{content_type}"
        params  = {"page[limit]": 50}
        if modified_since:
            params["filter[changed][value]"]    = modified_since
            params["filter[changed][operator]"] = ">="
        records = []

        while url:
            r = requests.get(url, headers=headers, params=params, timeout=60)
            r.raise_for_status()
            d = r.json()
            records.extend(d.get("data", []))
            print(f"    {content_type}: {len(records):,} records so far")
            url    = d.get("links", {}).get("next", {}).get("href")
            params = {}

        results[content_type] = records

    return results


# TODO: Confirm content types in scope with Anna Kim before first run
CONTENT_TYPES = [
    # "page",
    # "event",
    # "press_release",
    # "exhibit",
]


def run(incremental=True):
    mode = "incremental" if incremental else "full load"
    print(f"\n{'='*60}\n{SOURCE_SYSTEM} -- {mode}\n{'='*60}\n")
    if not CONTENT_TYPES:
        print("WARNING: CONTENT_TYPES list is empty. Confirm scope with Anna Kim before running.")
        return
    modified_since = None
    if incremental:
        modified_since = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
    extracted_at = datetime.now(timezone.utc).isoformat()
    headers = authenticate()
    for obj_name, records in extract(headers, modified_since).items():
        try:
            count = land_to_bronze(records, SOURCE_SYSTEM, obj_name, extracted_at)
            log_run(SOURCE_SYSTEM, obj_name, "success", count)
        except Exception as e:
            print(f"    ERROR on {obj_name}: {e}")
            log_run(SOURCE_SYSTEM, obj_name, "failed", 0, str(e))
    print(f"\nComplete: {datetime.now(timezone.utc).isoformat()}")


if __name__ == "__main__":
    run(incremental="--full" not in sys.argv)
