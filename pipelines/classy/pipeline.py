"""
Classy (GoFundMe Pro) -> Snowflake Bronze ingestion pipeline
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

SOURCE_SYSTEM = "CLASSY"


def authenticate():
    r = requests.post("https://api.classy.org/oauth2/auth", timeout=30, data={
        "grant_type":    "client_credentials",
        "client_id":     secret("CLASSY-CLIENT-ID"),
        "client_secret": secret("CLASSY-CLIENT-SECRET"),
    })
    r.raise_for_status()
    return r.json()["access_token"]


def extract(access_token, modified_since=None):
    base    = secret("CLASSY-API-URL")
    org_id  = secret("CLASSY-ORG-ID")
    headers = {"Authorization": f"Bearer {access_token}"}
    results = {}

    for obj_name, endpoint in ENDPOINTS:
        url     = f"{base}{endpoint.format(org_id=org_id)}"
        params  = {"per_page": 100, "page": 1}
        if modified_since:
            params["updated_gte"] = modified_since
        records = []

        while url:
            r = requests.get(url, headers=headers, params=params, timeout=60)
            r.raise_for_status()
            d = r.json()
            records.extend(d.get("data", []))
            print(f"    {obj_name}: {len(records):,} records so far")
            url    = d.get("next_page_url")
            params = {}

        results[obj_name] = records

    return results


ENDPOINTS = [
    ("Campaigns",    "organizations/{org_id}/campaigns"),
    ("Transactions", "organizations/{org_id}/transactions"),
    ("Donors",       "organizations/{org_id}/members"),
]


def run(incremental=True):
    mode = "incremental" if incremental else "full load"
    print(f"\n{'='*60}\n{SOURCE_SYSTEM} -- {mode}\n{'='*60}\n")
    modified_since = None
    if incremental:
        modified_since = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
    extracted_at = datetime.now(timezone.utc).isoformat()
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
