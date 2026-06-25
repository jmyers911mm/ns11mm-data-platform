"""
Salesforce NPS -> Snowflake Bronze ingestion pipeline
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

SOURCE_SYSTEM = "SALESFORCE_NPS"


def authenticate():
    instance_url = secret("SFNPS-INSTANCE-URL")
    r = requests.post(f"{instance_url}/services/oauth2/token", timeout=30, data={
        "grant_type":    "password",
        "client_id":     secret("SFNPS-CLIENT-ID"),
        "client_secret": secret("SFNPS-CLIENT-SECRET"),
        "username":      secret("SFNPS-SERVICE-USER"),
        "password":      secret("SFNPS-SERVICE-PASSWORD") + secret("SFNPS-SECURITY-TOKEN"),
    })
    r.raise_for_status()
    d = r.json()
    return d["access_token"], d["instance_url"]


def extract(auth, modified_since=None):
    access_token, instance_url = auth
    headers = {"Authorization": f"Bearer {access_token}"}
    api_ver = secret("SFNPS-API-VERSION")
    results = {}

    for obj_name, fields in OBJECTS.items():
        field_list = ", ".join(fields)
        query = f"SELECT {field_list} FROM {obj_name}"
        if modified_since:
            query += f" WHERE LastModifiedDate >= {modified_since}"

        url, params, records = f"{instance_url}/services/data/{api_ver}/query", {"q": query}, []
        while True:
            r = requests.get(url, headers=headers, params=params, timeout=60)
            r.raise_for_status()
            d = r.json()
            records.extend(d["records"])
            print(f"    {obj_name}: {len(records):,} / {d['totalSize']:,}")
            if d.get("done"):
                break
            url, params = instance_url + d["nextRecordsUrl"], {}
        results[obj_name] = records

    return results


OBJECTS = {
    "Contact":     ["Id", "FirstName", "LastName", "Email", "Phone", "AccountId", "OwnerId", "CreatedDate", "LastModifiedDate"],
    "Account":     ["Id", "Name", "Type", "BillingCity", "BillingState", "BillingCountry", "CreatedDate", "LastModifiedDate"],
    "Opportunity": ["Id", "Name", "AccountId", "Amount", "StageName", "Type", "CloseDate", "CreatedDate", "LastModifiedDate"],
    "Campaign":    ["Id", "Name", "Status", "Type", "StartDate", "EndDate", "NumberOfLeads", "NumberOfContacts", "AmountWonOpportunities", "CreatedDate", "LastModifiedDate"],
    "Task":        ["Id", "WhoId", "WhatId", "Subject", "Status", "Priority", "ActivityDate", "CreatedDate", "LastModifiedDate"],
}


def run(incremental=True):
    mode = "incremental" if incremental else "full load"
    print(f"\n{'='*60}\n{SOURCE_SYSTEM} -- {mode}\n{'='*60}\n")
    modified_since = None
    if incremental:
        modified_since = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
    extracted_at = datetime.now(timezone.utc).isoformat()
    auth = authenticate()
    for obj_name, records in extract(auth, modified_since).items():
        try:
            count = land_to_bronze(records, SOURCE_SYSTEM, obj_name, extracted_at)
            log_run(SOURCE_SYSTEM, obj_name, "success", count)
        except Exception as e:
            print(f"    ERROR on {obj_name}: {e}")
            log_run(SOURCE_SYSTEM, obj_name, "failed", 0, str(e))
    print(f"\nComplete: {datetime.now(timezone.utc).isoformat()}")


if __name__ == "__main__":
    run(incremental="--full" not in sys.argv)
