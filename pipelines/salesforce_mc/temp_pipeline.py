"""
Salesforce Marketing Cloud -> Snowflake Bronze ingestion pipeline
NS11MM Data Platform

Usage:
    python temp_pipeline.py --discover              # discover available data extensions
    python temp_pipeline.py --full --limit 1000     # full load, 1000 records per object
    python temp_pipeline.py                         # incremental (last 24 hours)
    python temp_pipeline.py --full                  # full historical load

Local testing (no Azure Key Vault):
    $env:SFMC_LOCAL_TEST    = "true"
    $env:SFMC_CLIENT_ID     = "your_client_id"
    $env:SFMC_CLIENT_SECRET = "your_client_secret"
    $env:SFMC_AUTH_URI      = "https://mcfjc2j5hvw05w7-pstpxnsxzxkm.auth.marketingcloudapis.com/"
    $env:SFMC_REST_URI      = "https://mcfjc2j5hvw05w7-pstpxnsxzxkm.rest.marketingcloudapis.com/"
    $env:SNOWFLAKE_ACCOUNT  = "om01578.east-us.azure"
    $env:SNOWFLAKE_USER     = "jmyers@911memorial.org"
    $env:SNOWFLAKE_PASSWORD = "your_snowflake_password"
    $env:SNOWFLAKE_DATABASE = "NS11MM_DW_DEV"
    $env:SNOWFLAKE_SCHEMA   = "RAW"
    $env:SNOWFLAKE_ROLE     = "LOADER_ROLE"
    $env:SNOWFLAKE_WAREHOUSE = "COMPUTE_WH"
"""

import os
import sys
import json
import re
import requests
from datetime import datetime, timezone, timedelta

# --- LOCAL TEST MODE ---
_LOCAL_TEST = os.environ.get("SFMC_LOCAL_TEST", "").lower() == "true"

if _LOCAL_TEST:
    print("⚠  LOCAL TEST MODE — reading credentials from environment variables, not Key Vault")

    def secret(name):
        env_map = {
            "SFMC-CLIENT-ID":     "SFMC_CLIENT_ID",
            "SFMC-CLIENT-SECRET": "SFMC_CLIENT_SECRET",
            "SFMC-AUTH-URI":      "SFMC_AUTH_URI",
            "SFMC-REST-URI":      "SFMC_REST_URI",
        }
        env_key = env_map.get(name)
        if not env_key:
            raise ValueError(f"No environment variable mapping for secret: {name}")
        value = os.environ.get(env_key)
        if not value:
            raise EnvironmentError(
                f"Environment variable {env_key} is not set. "
                f"Set it before running in local test mode."
            )
        return value

    import snowflake.connector

    def _get_local_snowflake_connection():
        return snowflake.connector.connect(
            account=os.environ["SNOWFLAKE_ACCOUNT"],
            user=os.environ["SNOWFLAKE_USER"],
            password=os.environ["SNOWFLAKE_PASSWORD"],
            database=os.environ["SNOWFLAKE_DATABASE"],
            schema=os.environ["SNOWFLAKE_SCHEMA"],
            role=os.environ["SNOWFLAKE_ROLE"],
            warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
            authenticator="username_password_mfa",
        )

    def land_to_bronze(records, source_system, object_name, extracted_at):
        if not records:
            print(f"    {object_name}: 0 records — skipping")
            return 0

        table_name = f"RAW_{source_system}_{object_name}".upper()
        conn = _get_local_snowflake_connection()
        cur = conn.cursor()

        cur.execute(f"""
            CREATE TABLE IF NOT EXISTS {table_name} (
                _extracted_at     TIMESTAMP_TZ,
                _source_system    VARCHAR,
                _source_object    VARCHAR,
                _record_id        VARCHAR,
                _raw_data         VARIANT
            )
        """)

        rows_inserted = 0
        for record in records:
            record_id = str(record.get("Id", record.get("id", record.get("SendID", extracted_at))))
            cur.execute(
                """
                INSERT INTO {table_name}
                    (_extracted_at, _source_system, _source_object, _record_id, _raw_data)
                SELECT
                    %s::TIMESTAMP_TZ,
                    %s,
                    %s,
                    %s,
                    PARSE_JSON(%s)
                """.format(table_name=table_name),
                (extracted_at, source_system, object_name, record_id, json.dumps(record))
            )
            rows_inserted += 1

        conn.commit()
        cur.close()
        conn.close()
        print(f"    {object_name}: {rows_inserted} records landed to {table_name}")
        return rows_inserted

    def log_run(source_system, object_name, status, record_count, error_message=None):
        msg = f"    LOG: {source_system}/{object_name} — {status} ({record_count} records)"
        if error_message:
            msg += f" — {error_message}"
        print(msg)

else:
    from shared.keyvault import secret
    from shared.snowflake_client import land_to_bronze, log_run


SOURCE_SYSTEM  = "SALESFORCE_MC"
SFMC_SUBDOMAIN = "mcfjc2j5hvw05w7-pstpxnsxzxkm"
SOAP_URL       = f"https://{SFMC_SUBDOMAIN}.soap.marketingcloudapis.com/Service.asmx"


def authenticate():
    auth_uri = secret("SFMC-AUTH-URI")
    r = requests.post(f"{auth_uri}v2/token", timeout=30, json={
        "grant_type":    "client_credentials",
        "client_id":     secret("SFMC-CLIENT-ID"),
        "client_secret": secret("SFMC-CLIENT-SECRET"),
    })
    r.raise_for_status()
    token = r.json()["access_token"]
    print(f"    Authentication: OK")
    return token


def soap_request(access_token, body_xml):
    """Send a SOAP request and return (status_code, response_text)."""
    envelope = f"""<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
            xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing">
  <s:Header>
    <a:Action s:mustUnderstand="1">Retrieve</a:Action>
    <a:To s:mustUnderstand="1">{SOAP_URL}</a:To>
    <fueloauth xmlns="http://exacttarget.com">{access_token}</fueloauth>
  </s:Header>
  <s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    {body_xml}
  </s:Body>
</s:Envelope>"""
    r = requests.post(
        SOAP_URL,
        data=envelope.encode("utf-8"),
        headers={"Content-Type": "text/xml; charset=utf-8", "SOAPAction": "Retrieve"},
        timeout=60,
    )
    return r.status_code, r.text


def parse_soap_de_rows(xml_text, field_names):
    """
    Parse SFMC SOAP DataExtensionObject response into list of dicts.
    Each <Results> block contains <Properties> with <Name>/<Value> pairs.
    """
    records = []
    for result_block in re.findall(
        r"<Results[^>]*>(.*?)</Results>", xml_text, re.DOTALL
    ):
        record = {}
        for prop in re.findall(
            r"<Properties[^>]*>(.*?)</Properties>", result_block, re.DOTALL
        ):
            name_m  = re.search(r"<Name>(.*?)</Name>", prop)
            value_m = re.search(r"<Value>(.*?)</Value>", prop)
            if name_m and value_m:
                record[name_m.group(1)] = value_m.group(1)
        if record:
            records.append(record)
    return records


def fetch_de_by_customer_key(access_token, customer_key, obj_name,
                              field_names, batch_size=500,
                              modified_since=None):
    """
    Pull all rows from a data extension identified by CustomerKey via SOAP.
    Handles continuation tokens for pagination.
    Returns list of dicts.
    """
    props_xml = "\n".join(
        f"        <Properties>{f}</Properties>" for f in field_names
    )

    filter_xml = ""
    if modified_since:
        # Use ModifiedDate or EventDate if available; fall back to no filter
        filter_xml = f"""
        <Filter xsi:type="SimpleFilterPart"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <Property>ModifiedDate</Property>
          <SimpleOperator>greaterThan</SimpleOperator>
          <DateValue>{modified_since}</DateValue>
        </Filter>"""

    all_records = []
    continuation_request_id = None
    page = 1

    while True:
        if continuation_request_id:
            # Continue pulling the next page using the RequestID
            body_xml = f"""
    <RetrieveRequestMsg xmlns="http://exacttarget.com/wsdl/partnerAPI">
      <RetrieveRequest>
        <ContinueRequest>{continuation_request_id}</ContinueRequest>
      </RetrieveRequest>
    </RetrieveRequestMsg>"""
        else:
            body_xml = f"""
    <RetrieveRequestMsg xmlns="http://exacttarget.com/wsdl/partnerAPI">
      <RetrieveRequest>
        <ObjectType>DataExtensionObject[{customer_key}]</ObjectType>
{props_xml}{filter_xml}
        <Options>
          <BatchSize>{batch_size}</BatchSize>
        </Options>
      </RetrieveRequest>
    </RetrieveRequestMsg>"""

        status, xml_text = soap_request(access_token, body_xml)

        if status != 200:
            print(f"    {obj_name} page {page}: SOAP error {status}")
            break

        # Check overall status
        overall = re.search(r"<OverallStatus>(.*?)</OverallStatus>", xml_text)
        overall_status = overall.group(1) if overall else "Unknown"

        records = parse_soap_de_rows(xml_text, field_names)
        all_records.extend(records)
        print(f"    {obj_name} page {page}: {len(records)} records "
              f"(total so far: {len(all_records)})  status={overall_status}")

        # Check for more pages
        if "MoreDataAvailable" in overall_status:
            req_id_m = re.search(r"<RequestID>(.*?)</RequestID>", xml_text)
            if req_id_m:
                continuation_request_id = req_id_m.group(1)
                page += 1
            else:
                break
        else:
            break

    return all_records


def discover(access_token):
    """
    Print all 346 data extensions with their CustomerKeys.
    Focus on the ones most relevant to email tracking.
    Run with: python temp_pipeline.py --discover
    """
    print(f"\n{'='*60}")
    print("SFMC DATA EXTENSION INVENTORY (relevant to email tracking)")
    print(f"{'='*60}\n")

    status, xml_text = soap_request(access_token, """
    <RetrieveRequestMsg xmlns="http://exacttarget.com/wsdl/partnerAPI">
      <RetrieveRequest>
        <ObjectType>DataExtension</ObjectType>
        <Properties>Name</Properties>
        <Properties>CustomerKey</Properties>
        <Properties>IsSendable</Properties>
        <Properties>RowCount</Properties>
      </RetrieveRequest>
    </RetrieveRequestMsg>""")

    print(f"SOAP status: {status}")
    if status == 200:
        names     = re.findall(r"<Name>(.*?)</Name>", xml_text)
        keys      = re.findall(r"<CustomerKey>(.*?)</CustomerKey>", xml_text)
        sendables = re.findall(r"<IsSendable>(.*?)</IsSendable>", xml_text)
        rows      = re.findall(r"<RowCount>(.*?)</RowCount>", xml_text)

        # Keyword filter for tracking-related DEs
        keywords = ["sent", "open", "click", "bounce", "unsub", "log",
                    "subscriber", "track", "engagement", "contact"]

        print("\nALL DATA EXTENSIONS (346 total):\n")
        for i, (name, key) in enumerate(zip(names, keys)):
            sendable = sendables[i] if i < len(sendables) else "?"
            row_count = rows[i] if i < len(rows) else "?"
            print(f"  Name={name}")
            print(f"    CustomerKey={key}")
            print(f"    IsSendable={sendable}  RowCount={row_count}")

        print(f"\n--- TRACKING-RELATED (keyword match) ---")
        for i, (name, key) in enumerate(zip(names, keys)):
            if any(kw in name.lower() for kw in keywords):
                row_count = rows[i] if i < len(rows) else "?"
                print(f"  ✅ Name={name}  CustomerKey={key}  RowCount={row_count}")

    print(f"\n{'='*60}")
    print("DISCOVERY COMPLETE")
    print(f"{'='*60}\n")


# --- Data extensions to extract ---
# CustomerKeys confirmed from discovery run on 2026-06-24
# Update field lists once a sample row is inspected
DATA_EXTENSIONS = {
    "Tracking_Sent": {
        "customer_key": "C3881CCD-9FE2-44ED-8DFF-B70FBDE19759",
        "fields": [
            "JobID", "BatchID", "SubscriberID", "SubscriberKey",
            "EventDate", "Domain", "SendID", "TriggeredSendDefinitionObjectID",
        ],
    },
    "Tracking_Open": {
        "customer_key": "D96472EB-4359-44F6-A21C-E1FCAD028621",
        "fields": [
            "JobID", "BatchID", "SubscriberID", "SubscriberKey",
            "EventDate", "Domain", "IsUnique",
        ],
    },
    "Technical_SendLog": {
        "customer_key": "53426E0E-69D5-4B13-9CA2-348B06AAD5CE",
        "fields": [
            "JobID", "BatchID", "SubscriberID", "SubscriberKey",
            "EventDate", "Domain",
        ],
    },
    "Enhanced_SendLog": {
        "customer_key": "D99343CA-958A-45CD-94E4-AE75B32E77FF",
        "fields": [
            "JobID", "BatchID", "SubscriberID", "SubscriberKey",
            "EventDate", "Domain",
        ],
    },
    "All_Subscribers": {
        "customer_key": "6AB3A08E-E99D-4358-96E8-E0668353D53F",
        "fields": [
            "SubscriberKey", "EmailAddress", "Status",
            "DateUnsubscribed", "DateHeld",
        ],
    },
}


def extract(access_token, modified_since=None, limit=None):
    results = {}
    batch_size = limit if limit else 2500

    for obj_name, config in DATA_EXTENSIONS.items():
        customer_key = config["customer_key"]
        fields       = config["fields"]

        print(f"\n  Extracting {obj_name} (key={customer_key})...")

        try:
            records = fetch_de_by_customer_key(
                access_token,
                customer_key,
                obj_name,
                fields,
                batch_size=batch_size,
                modified_since=modified_since,
            )

            if limit:
                records = records[:limit]

            print(f"    {obj_name}: {len(records)} total records fetched")
            results[obj_name] = records

        except Exception as e:
            print(f"    {obj_name}: ERROR — {e}")
            results[obj_name] = []

    return results


def run(incremental=True, limit=None):
    mode = "incremental" if incremental else "full load"
    if limit:
        mode += f" (limit: {limit} records per object)"
    print(f"\n{'='*60}\n{SOURCE_SYSTEM} -- {mode}\n{'='*60}\n")

    extracted_at   = datetime.now(timezone.utc).isoformat()
    modified_since = None
    if incremental:
        modified_since = (
            datetime.now(timezone.utc) - timedelta(days=1)
        ).strftime("%Y-%m-%dT%H:%M:%SZ")

    access_token = authenticate()

    for obj_name, records in extract(
        access_token, modified_since, limit=limit
    ).items():
        try:
            count = land_to_bronze(records, SOURCE_SYSTEM, obj_name, extracted_at)
            log_run(SOURCE_SYSTEM, obj_name, "success", count)
        except Exception as e:
            print(f"    ERROR landing {obj_name}: {e}")
            log_run(SOURCE_SYSTEM, obj_name, "failed", 0, str(e))

    print(f"\nComplete: {datetime.now(timezone.utc).isoformat()}")


if __name__ == "__main__":
    if "--discover" in sys.argv:
        print("\n⚠  DISCOVERY MODE — no data will be written to Snowflake\n")
        token = authenticate()
        discover(token)
        sys.exit(0)

    limit = None
    if "--limit" in sys.argv:
        idx = sys.argv.index("--limit")
        try:
            limit = int(sys.argv[idx + 1])
        except (IndexError, ValueError):
            print("ERROR: --limit requires an integer value, e.g. --limit 1000")
            sys.exit(1)

    run(incremental="--full" not in sys.argv, limit=limit)