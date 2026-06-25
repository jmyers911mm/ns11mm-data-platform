"""
Blackbaud Financial Edge NXT -> Snowflake Bronze ingestion pipeline
NS11MM Data Platform

Usage:
    python pipeline.py           # incremental (last 24 hours)
    python pipeline.py --full    # full historical load (first run only)

NOTE: Blackbaud app must be approved by org's Blackbaud Admin before first run.
NOTE: The refresh token is renewed on each run. LOADER_ROLE needs Key Vault write
      access to store the updated refresh token, or Kenny must update it manually.
"""

import sys
import requests
from datetime import datetime, timezone, timedelta

from shared.keyvault import secret
from shared.snowflake_client import land_to_bronze, log_run

SOURCE_SYSTEM = "BLACKBAUD_NXT"


def authenticate():
    r = requests.post("https://oauth2.sky.blackbaud.com/token", timeout=30, data={
        "grant_type":    "refresh_token",
        "refresh_token": secret("BB-REFRESH-TOKEN"),
        "client_id":     secret("BB-CLIENT-ID"),
        "client_secret": secret("BB-CLIENT-SECRET"),
    })
    r.raise_for_status()
    d = r.json()
    # TODO: store d["refresh_token"] back to Key Vault (requires Key Vault write access)
    # Coordinate with Kenny to enable Key Vault Secrets Officer role on Function App identity
    return d["access_token"]


def extract(access_token, modified_since=None):
    base    = "https://api.sky.blackbaud.com/generalledger/v1"
    headers = {
        "Authorization":           f"Bearer {access_token}",
        "Bb-Api-Subscription-Key": secret("BB-SUBSCRIPTION-KEY"),
    }
    results = {}

    for obj_name, endpoint in ENDPOINTS:
        url, records = f"{base}/{endpoint}", []
        params = {"limit": 500}
        if modified_since:
            params["last_modified"] = modified_since

        while url:
            r = requests.get(url, headers=headers, params=params, timeout=60)
            r.raise_for_status()
            d = r.json()
            records.extend(d.get("value", []))
            print(f"    {obj_name}: {len(records):,} records so far")
            url    = d.get("nextLink")
            params = {}

        results[obj_name] = records

    return results


ENDPOINTS = [
    ("Accounts",       "accounts"),
    ("JournalEntries", "journalentries"),
    ("Transactions",   "transactions"),
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
