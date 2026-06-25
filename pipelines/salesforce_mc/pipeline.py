"""
Salesforce Marketing Cloud -> Snowflake Bronze ingestion pipeline
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

SOURCE_SYSTEM = "SALESFORCE_MC"


def authenticate():
    # Auth URI confirmed: https://mcfjc2j5hvw05w7-pstpxnsxzxkm.auth.marketingcloudapis.com/
    auth_uri = secret("SFMC-AUTH-URI")
    r = requests.post(f"{auth_uri}v2/token", timeout=30, json={
        "grant_type":    "client_credentials",
        "client_id":     secret("SFMC-CLIENT-ID"),
        "client_secret": secret("SFMC-CLIENT-SECRET"),
        "account_id":    secret("SFMC-ACCOUNT-MID"),
    })
    r.raise_for_status()
    return r.json()["access_token"]


def extract(access_token, modified_since=None):
    # REST URI confirmed: https://mcfjc2j5hvw05w7-pstpxnsxzxkm.rest.marketingcloudapis.com/
    rest_uri = secret("SFMC-REST-URI")
    headers  = {"Authorization": f"Bearer {access_token}"}
    results  = {}

    for event_type in ["sent", "open", "click", "bounce", "unsubscribe"]:
        r = requests.get(
            f"{rest_uri}data/v1/async/dataextensions/key:tracking_{event_type}/rows",
            headers=headers, timeout=60
        )
        r.raise_for_status()
        results[f"Tracking_{event_type.capitalize()}"] = r.json().get("items", [])

    r = requests.get(f"{rest_uri}asset/v1/content/categories", headers=headers, timeout=60)
    r.raise_for_status()
    results["Subscribers"] = r.json().get("items", [])

    return results


def run(incremental=True):
    mode = "incremental" if incremental else "full load"
    print(f"\n{'='*60}\n{SOURCE_SYSTEM} -- {mode}\n{'='*60}\n")
    extracted_at = datetime.now(timezone.utc).isoformat()
    modified_since = None
    if incremental:
        modified_since = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
    access_token = authenticate()
    for obj_name, records in extract(access_token, modified_since).items():
        try:
            count = land_to_bronze(records, SOURCE_SYSTEM, obj_name, extracted_at)
            log_run(SOURCE_SYSTEM, obj_name, "success", count)
        except Exception as e:
            print(f"    ERROR on {obj_name}: {e}")
            log_run(SOURCE_SYSTEM, obj_name, "failed", 0, str(e))
    print(f"\nComplete: {datetime.now(timezone.utc).isoformat()}")


if __name__ == "__main__":
    run(incremental="--full" not in sys.argv)
