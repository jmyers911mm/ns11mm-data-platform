"""
Shopify -> Snowflake Bronze ingestion pipeline
NS11MM Data Platform

Usage:
    python pipeline.py           # incremental (last 24 hours)
    python pipeline.py --full    # full historical load (first run only)
"""

import sys
import re
import requests
from datetime import datetime, timezone, timedelta

from shared.keyvault import secret
from shared.snowflake_client import land_to_bronze, log_run

SOURCE_SYSTEM = "SHOPIFY"


def authenticate():
    return {
        "X-Shopify-Access-Token": secret("SHOPIFY-ACCESS-TOKEN"),
        "Content-Type": "application/json",
    }


def _next_link(link_header):
    """Extract next page URL from Shopify Link response header."""
    match = re.search(r'<([^>]+)>;\s*rel="next"', link_header)
    return match.group(1) if match else None


def extract(headers, modified_since=None):
    domain  = secret("SHOPIFY-SHOP-DOMAIN")
    version = secret("SHOPIFY-API-VERSION")
    base    = f"https://{domain}/admin/api/{version}"
    results = {}

    for obj_name, endpoint, record_key in ENDPOINTS:
        url     = f"{base}/{endpoint}"
        params  = {"limit": 250, "status": "any"}
        if modified_since:
            params["updated_at_min"] = modified_since
        records = []

        while url:
            r = requests.get(url, headers=headers, params=params, timeout=60)
            r.raise_for_status()
            batch = r.json().get(record_key, [])
            records.extend(batch)
            print(f"    {obj_name}: {len(records):,} records so far")
            url    = _next_link(r.headers.get("Link", ""))
            params = {}

        results[obj_name] = records

    return results


ENDPOINTS = [
    ("Orders",      "orders.json",          "orders"),
    ("Customers",   "customers.json",        "customers"),
    ("Products",    "products.json",         "products"),
    ("Inventory",   "inventory_items.json",  "inventory_items"),
]


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
