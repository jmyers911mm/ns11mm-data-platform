"""
Vena Solutions (FP&A) -> Snowflake Bronze ingestion pipeline
NS11MM Data Platform

Usage:
    python pipeline.py           # incremental (last 24 hours)
    python pipeline.py --full    # full historical load (first run only)

NOTE: Populate MODELS dict with Vena model IDs after confirming with Finance team.
NOTE: Confirm Vena API is enabled by Vena Admin before first run.
"""

import sys
import requests
from datetime import datetime, timezone, timedelta

from shared.keyvault import secret
from shared.snowflake_client import land_to_bronze, log_run

SOURCE_SYSTEM = "VENA"


def authenticate():
    base = secret("VENA-INSTANCE-URL")
    r = requests.post(f"{base}/api/login", timeout=30, json={
        "username": secret("VENA-CLIENT-ID"),
        "password": secret("VENA-API-SECRET"),
    })
    r.raise_for_status()
    return r.json().get("token")


def extract(access_token, modified_since=None):
    base    = secret("VENA-INSTANCE-URL")
    headers = {"Authorization": f"Bearer {access_token}"}
    results = {}

    for model_name, model_id in MODELS.items():
        r = requests.get(
            f"{base}/api/models/{model_id}/export",
            headers=headers, timeout=120
        )
        r.raise_for_status()
        records = r.json().get("data", [])
        results[model_name] = records
        print(f"    {model_name}: {len(records):,} records")

    return results


# TODO: Populate with actual Vena model IDs after confirming with Finance team
# Example: "OperatingBudgetFY26": "model-id-from-vena-admin"
MODELS = {}


def run(incremental=True):
    mode = "incremental" if incremental else "full load"
    print(f"\n{'='*60}\n{SOURCE_SYSTEM} -- {mode}\n{'='*60}\n")
    if not MODELS:
        print("WARNING: MODELS dict is empty. Populate with Vena model IDs before running.")
        return
    extracted_at = datetime.now(timezone.utc).isoformat()
    access_token = authenticate()
    for obj_name, records in extract(access_token).items():
        try:
            count = land_to_bronze(records, SOURCE_SYSTEM, obj_name, extracted_at)
            log_run(SOURCE_SYSTEM, obj_name, "success", count)
        except Exception as e:
            print(f"    ERROR on {obj_name}: {e}")
            log_run(SOURCE_SYSTEM, obj_name, "failed", 0, str(e))
    print(f"\nComplete: {datetime.now(timezone.utc).isoformat()}")


if __name__ == "__main__":
    run(incremental="--full" not in sys.argv)
