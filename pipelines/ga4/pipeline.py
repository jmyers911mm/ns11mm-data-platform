"""
Google Analytics 4 -> Snowflake Bronze ingestion pipeline
NS11MM Data Platform

Usage:
    python pipeline.py           # incremental (yesterday's data)
    python pipeline.py --full    # full historical load (first run only)
"""

import sys
import json
from datetime import datetime, timezone, timedelta

from google.analytics.data_v1beta import BetaAnalyticsDataClient
from google.analytics.data_v1beta.types import RunReportRequest, DateRange, Metric, Dimension
from google.oauth2.service_account import Credentials

from shared.keyvault import secret
from shared.snowflake_client import land_to_bronze, log_run

SOURCE_SYSTEM = "GA4"


def authenticate():
    key_data    = json.loads(secret("GA4-SERVICE-ACCOUNT-JSON"))
    credentials = Credentials.from_service_account_info(
        key_data,
        scopes=["https://www.googleapis.com/auth/analytics.readonly"]
    )
    return BetaAnalyticsDataClient(credentials=credentials)


def extract(client, modified_since=None):
    property_id = f"properties/{secret('GA4-PROPERTY-ID')}"
    yesterday   = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%d")

    # For full load, use a wider date range
    start_date = modified_since[:10] if modified_since else "2020-01-01"
    date_range  = DateRange(start_date=start_date, end_date=yesterday)

    request = RunReportRequest(
        property    = property_id,
        date_ranges = [date_range],
        metrics     = [Metric(name=m) for m in ["sessions", "activeUsers", "screenPageViews", "bounceRate", "averageSessionDuration"]],
        dimensions  = [Dimension(name=d) for d in ["date", "sessionSource", "sessionMedium", "country", "deviceCategory"]],
    )
    response = client.run_report(request)

    records = []
    for row in response.rows:
        record = {}
        for i, dim in enumerate(response.dimension_headers):
            record[dim.name] = row.dimension_values[i].value
        for i, met in enumerate(response.metric_headers):
            record[met.name] = row.metric_values[i].value
        records.append(record)

    print(f"    SessionReport: {len(records):,} records")
    return {"SessionReport": records}


def run(incremental=True):
    mode = "incremental" if incremental else "full load"
    print(f"\n{'='*60}\n{SOURCE_SYSTEM} -- {mode}\n{'='*60}\n")
    modified_since = None
    if incremental:
        modified_since = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
    extracted_at = datetime.now(timezone.utc).isoformat()
    client = authenticate()
    for obj_name, records in extract(client, modified_since).items():
        try:
            count = land_to_bronze(records, SOURCE_SYSTEM, obj_name, extracted_at)
            log_run(SOURCE_SYSTEM, obj_name, "success", count)
        except Exception as e:
            print(f"    ERROR on {obj_name}: {e}")
            log_run(SOURCE_SYSTEM, obj_name, "failed", 0, str(e))
    print(f"\nComplete: {datetime.now(timezone.utc).isoformat()}")


if __name__ == "__main__":
    run(incremental="--full" not in sys.argv)
