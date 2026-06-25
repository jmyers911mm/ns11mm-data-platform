"""
Meta Ads (Facebook/Instagram) -> Snowflake Bronze ingestion pipeline
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

SOURCE_SYSTEM = "META_ADS"


def authenticate():
    return {
        "Authorization": f"Bearer {secret('META-SYSTEM-USER-TOKEN')}",
        "Content-Type":  "application/json",
    }


def extract(headers, modified_since=None):
    account_id = secret("META-AD-ACCOUNT-ID")
    api_ver    = "v20.0"
    base       = f"https://graph.facebook.com/{api_ver}/{account_id}"
    yesterday  = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%d")
    start_date = modified_since[:10] if modified_since else "2020-01-01"
    results    = {}

    params = {
        "fields":     "campaign_id,campaign_name,impressions,clicks,spend,reach,cpm,cpc",
        "time_range": f'{{"since":"{start_date}","until":"{yesterday}"}}',
        "level":      "campaign",
        "limit":      500,
    }
    records, url = [], f"{base}/insights"

    while url:
        r = requests.get(url, headers=headers, params=params, timeout=60)
        r.raise_for_status()
        d = r.json()
        records.extend(d.get("data", []))
        print(f"    CampaignInsights: {len(records):,} records so far")
        url    = d.get("paging", {}).get("next")
        params = {}

    results["CampaignInsights"] = records
    return results


def run(incremental=True):
    mode = "incremental" if incremental else "full load"
    print(f"\n{'='*60}\n{SOURCE_SYSTEM} -- {mode}\n{'='*60}\n")
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
