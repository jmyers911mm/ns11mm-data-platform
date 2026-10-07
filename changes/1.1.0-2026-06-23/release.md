# 1.1.0

- **Date:** 2026-06-23
- **Version:** 1.1.0

*Errata (2026-07-29): duplicate version number — this is the first (earlier) 1.1.0, dated 2026-06-23. A second 1.1.0 dated 2026-06-24 appears above. Entries are kept as written — disambiguate by date.*

## Bronze Ingestion Pipeline Framework

**Scope:** Raw data ingestion to Snowflake RAW schema only. dbt staging, Silver, and Gold are handled separately in `models/`.

### Shared Library (`pipelines/shared/`)

- `shared/__init__.py` — marks shared/ as a Python package importable by all pipelines
- `shared/keyvault.py` — Azure Key Vault client using `DefaultAzureCredential`; single `secret(name)` function used by all pipelines; singleton client pattern to avoid re-authentication on each call
- `shared/snowflake_client.py` — shared Snowflake connection, Bronze landing, and pipeline logging:
  - `get_connection()` — connects using Key Vault credentials; targets `NS11MM_DW_DEV.RAW` schema with `LOADER_ROLE`
  - `land_to_bronze()` — append-only insert of raw records as VARIANT (JSON) columns; creates table if not exists; never updates or deletes
  - `log_run()` — writes success/failed run record to `RAW.PIPELINE_LOG`; creates table if not exists
- `requirements-shared.txt` — shared dependencies: `azure-identity`, `azure-keyvault-secrets`, `snowflake-connector-python`, `requests`

### Source Pipelines (14 sources)

Each pipeline contains `authenticate()` and `extract()` functions unique to the source, plus a `run()` function identical across all pipelines that calls shared library functions for landing and logging.

| Source Folder | Source System | Auth Pattern | Schedule (UTC) |
|---|---|---|---|
| `salesforce_nps/` | Salesforce NPS (Sales Cloud for Nonprofits) | OAuth 2.0 Username-Password | 07:00 |
| `salesforce_mc/` | Salesforce Marketing Cloud | OAuth 2.0 Client Credentials | 07:15 |
| `gateway/` | Gateway Ticketing Galaxy | SQL Server read-only (pyodbc) via on-prem agent | 07:30 |
| `counterpoint/` | NCR CounterPoint POS | SQL Server read-only (pyodbc) via on-prem agent | 07:45 |
| `shopify/` | Shopify (E-commerce) | Custom App access token in header | 08:00 |
| `classy/` | GoFundMe Pro / Classy | OAuth 2.0 Client Credentials | 08:15 |
| `blackbaud/` | Blackbaud Financial Edge NXT | OAuth 2.0 Refresh Token (SKY API) | 08:30 |
| `vena/` | Vena Solutions (FP&A) | API key / Bearer token | 08:45 |
| `ga4/` | Google Analytics 4 | Google Service Account JSON key | 09:00 |
| `google_ads/` | Google Ads | OAuth 2.0 with Developer Token | 09:15 |
| `meta_ads/` | Meta Ads (Facebook/Instagram) | System User Access Token | 09:30 |
| `wufoo/` | Wufoo (Forms) | HTTP Basic Auth (API key) | 09:45 |
| `clicky/` | Clicky (Web Analytics) | API key + Site ID as query parameters | 10:00 |
| `drupal/` | Drupal CMS | Bearer token (JSON:API path; pending ADR) | 10:15 |

All pipelines support `--full` flag for initial historical load and default to incremental (last 24 hours) for nightly runs.

### Azure DevOps Deployment (14 YAML files)

One deployment YAML per source, placed in repo root:

`azure-pipelines-sfnps.yml`, `azure-pipelines-sfmc.yml`, `azure-pipelines-gateway.yml`, `azure-pipelines-counterpoint.yml`, `azure-pipelines-shopify.yml`, `azure-pipelines-classy.yml`, `azure-pipelines-blackbaud.yml`, `azure-pipelines-vena.yml`, `azure-pipelines-ga4.yml`, `azure-pipelines-googleads.yml`, `azure-pipelines-metaads.yml`, `azure-pipelines-wufoo.yml`, `azure-pipelines-clicky.yml`, `azure-pipelines-drupal.yml`

Each YAML includes:
- Path trigger scoped to `pipelines/<source>/` and `pipelines/shared/` — shared library changes redeploy all dependent pipelines
- PR trigger for validation on pull requests (Validate stage only; Deploy stage requires merge to main)
- Two-stage pipeline: Validate (import check) and Deploy (Azure Function App)
- Variables: `FUNCTION_APP_NAME`, `AZURE_SERVICE_CONNECTION`, `PYTHON_VERSION`

### Documentation

- `pipelines/README.md` — pipeline framework overview: folder structure, how pipelines work, running instructions, shared library usage, adding a new pipeline, nightly schedule, credential conventions, outstanding blockers, key contacts
- `NS11MM_Azure_IT_Setup_Request.docx` — IT setup request for Kenny covering Key Vault provisioning, Function App spec and naming convention, managed identity and Key Vault RBAC setup, outbound network access requirements, Azure DevOps service connection, and recommended 12-step setup sequence
- `NS11MM_Source_Credential_Intake.xlsx` — credential intake workbook with one tab per source; Key Vault secret names, collection hints, and status tracking for all 14 sources
- `ns11mm_bronze_pipelines_master.md` — master pipeline reference covering shared library, per-source guides, nightly schedule, and pipeline status tracker

### Snowflake Setup (one-time)

```sql
CREATE ROLE IF NOT EXISTS LOADER_ROLE;
GRANT USAGE ON DATABASE NS11MM_DW_DEV TO ROLE LOADER_ROLE;
GRANT USAGE ON SCHEMA NS11MM_DW_DEV.RAW TO ROLE LOADER_ROLE;
GRANT CREATE TABLE ON SCHEMA NS11MM_DW_DEV.RAW TO ROLE LOADER_ROLE;
GRANT INSERT ON FUTURE TABLES IN SCHEMA NS11MM_DW_DEV.RAW TO ROLE LOADER_ROLE;
GRANT ROLE LOADER_ROLE TO USER <pipeline_service_user>;
```

### Credential status at release

| Source | Status |
|---|---|
| Salesforce Marketing Cloud | Auth URI, REST URI, SOAP URI confirmed; Client ID collected; Client Secret requires regeneration; MID outstanding |
| All other sources | Pending Key Vault setup |

### Outstanding items before first pipeline run

- Kenny: provision `kv-ns11mm-dp-dev` Key Vault and `func-ns11mm-sfmc-dev` Function App per IT setup doc
- Jeremy: add Snowflake and SFMC credentials to Key Vault once provisioned; regenerate SFMC Client Secret
- Vena: populate `MODELS` dict in `pipelines/vena/pipeline.py` after confirming model IDs with Finance team
- Drupal: confirm DB vs JSON:API path (ADR required); populate `CONTENT_TYPES` list after scope confirmation with Anna Kim
- Blackbaud: registered app requires Blackbaud Admin approval; refresh token rotation requires Key Vault Secrets Officer role on Function App managed identity
- Gateway / CounterPoint: run via self-hosted agent on internal network, not Azure Functions; VM setup to be coordinated separately with Kenny

---
