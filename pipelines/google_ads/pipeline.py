"""
Google Ads -> Snowflake Bronze ingestion pipeline
NS11MM Data Platform

Usage:
    python pipeline.py           # incremental (last 24 hours)
    python pipeline.py --full    # full historical load (first run only)
"""

import sys
from datetime import datetime, timezone, timedelta

from google.ads.googleads.client import GoogleAdsClient

from shared.keyvault import secret
from shared.snowflake_client import land_to_bronze, log_run

SOURCE_SYSTEM = "GOOGLE_ADS"


def authenticate():
    config = {
        "developer_token":  secret("GADS-DEVELOPER-TOKEN"),
        "client_id":        secret("GADS-OAUTH-CLIENT-ID"),
        "client_secret":    secret("GADS-OAUTH-CLIENT-SECRET"),
        "refresh_token":    secret("GADS-OAUTH-REFRESH-TOKEN"),
        "login_customer_id": secret("GADS-MCC-CUSTOMER-ID"),
        "use_proto_plus":   True,
    }
    return GoogleAdsClient.load_from_dict(config)


def extract(client, modified_since=None):
    customer_id = secret("GADS-CLIENT-CUSTOMER-ID").replace("-", "")
    ga_service  = client.get_service("GoogleAdsService")
    yesterday   = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%d")
    start_date  = modified_since[:10] if modified_since else "2020-01-01"

    query = f"""
        SELECT campaign.id, campaign.name, campaign.status,
               metrics.impressions, metrics.clicks, metrics.cost_micros,
               metrics.conversions, segments.date
        FROM campaign
        WHERE segments.date BETWEEN '{start_date}' AND '{yesterday}'
    """

    response = ga_service.search_stream(customer_id=customer_id, query=query)
    records  = []
    for batch in response:
        for row in batch.results:
            records.append({
                "campaign_id":   row.campaign.id,
                "campaign_name": row.campaign.name,
                "status":        row.campaign.status.name,
                "impressions":   row.metrics.impressions,
                "clicks":        row.metrics.clicks,
                "cost_micros":   row.metrics.cost_micros,
                "conversions":   row.metrics.conversions,
                "date":          row.segments.date,
            })

    print(f"    CampaignPerformance: {len(records):,} records")
    return {"CampaignPerformance": records}


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
