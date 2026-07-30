# NS11MM Data Platform — Bronze Ingestion Pipelines

This folder contains all source ingestion pipelines for the NS11MM data platform. Each pipeline extracts raw data from a source system and lands it in the `RAW` schema of the env-selected database (default `NS11MM_DW_DEV`) as append-only VARIANT records.

**Scope:** Raw ingestion to Snowflake RAW only. dbt staging models, Silver, and Gold are handled separately in `models/`.

> **Status (July 2026): scaffolded, not deployed.** Production ingestion is
> currently seed/stage-based; the `pipeline.py` extract queries are unconfirmed
> placeholders and none of the Azure Function apps are deployed (all 14 deploy
> YAMLs are parked in `disabled/` — see `disabled/README.md`). The schedule table
> below describes the **planned** nightly cadence.

---

## Folder structure

```
pipelines/
├── README.md                    ← you are here
├── requirements-shared.txt      ← dependencies shared by all pipelines
│
├── shared/                      ← shared library: import from here, never copy
│   ├── __init__.py
│   ├── keyvault.py              ← Azure Key Vault secret fetching (vault URL env-selectable)
│   ├── snowflake_client.py      ← Snowflake connection, RAW landing, pipeline logging
│   └── refresh_log.py           ← appends per-table refresh results to docs/REFRESH_LOG.md
│
├── salesforce_nps/              ← Salesforce NPS (CRM)          [short name: sfnps]
├── salesforce_mc/               ← Salesforce Marketing Cloud    [short name: sfmc]
├── gateway/                     ← Gateway Ticketing Galaxy
├── counterpoint/                ← NCR CounterPoint POS
├── shopify/                     ← Shopify (E-commerce)
├── classy/                      ← GoFundMe Pro / Classy (Fundraising)
├── wufoo/                       ← Wufoo (Forms)
├── clicky/                      ← Clicky (Web Analytics)
├── ga4/                         ← Google Analytics 4
├── google_ads/                  ← Google Ads                    [short name: googleads]
├── meta_ads/                    ← Meta Ads (Facebook/Instagram) [short name: metaads]
├── vena/                        ← Vena Solutions (FP&A)
├── blackbaud/                   ← Blackbaud Financial Edge NXT
└── drupal/                      ← Drupal CMS
```

Each source folder contains:
- `pipeline.py` — authentication and extraction logic unique to that source
- `requirements.txt` — any dependencies beyond `requirements-shared.txt`

**Deployment YAMLs are parked.** All 14 Azure DevOps deployment YAML files
(`azure-pipelines-<shortname>.yml`) live in the repo-level `disabled/` folder, not
the repo root: ingestion is seed/stage-based today and the function scaffolding is
incomplete. See `disabled/README.md` for why and for the re-enable requirements
(add `function_app.py` + `host.json`, package `pipelines/shared/`, confirm the
source queries, move the YAML back to the repo root).

**Short-name mapping** (YAML/function-app names → source folders): `sfmc` →
`salesforce_mc`, `sfnps` → `salesforce_nps`, `googleads` → `google_ads`,
`metaads` → `meta_ads`; all other short names match their folder name.

**Environment selection.** The shared library reads its targets from Function App
settings (env vars), defaulting to dev:
- `NS11MM_KEYVAULT_URL` — Key Vault (default `https://kv-ns11mm-dp-dev.vault.azure.net/`)
- `NS11MM_SNOWFLAKE_DATABASE` — landing database (default `NS11MM_DW_DEV`)
- `NS11MM_SNOWFLAKE_WAREHOUSE` — ingestion warehouse (default `SOURCES_WH`)

---

## How pipelines work

Every pipeline follows the same five-step pattern:

1. **Authenticate** — fetch credentials from Azure Key Vault and authenticate with the source API
2. **Extract** — pull records from the source, handling pagination automatically
3. **Land** — write raw JSON records to `NS11MM_DW_DEV.RAW` as VARIANT columns (append-only)
4. **Log** — write a run record to `RAW.PIPELINE_LOG` (success or failed, with record count)
5. **Schedule** — Azure Functions Timer Trigger runs each pipeline nightly (see schedule below)

All shared logic (steps 3 and 4) lives in `shared/snowflake_client.py`. Each `pipeline.py` only contains what is unique to its source: the auth and extract functions.

---

## Running a pipeline

### Install dependencies (first time only)

```bash
# From repo root
pip install -r pipelines/requirements-shared.txt
pip install -r pipelines/<source_folder>/requirements.txt
```

### First run — full historical load

```bash
cd pipelines/<source_folder>
python pipeline.py --full
```

Run once only per source. Pulls complete history. After this, switch to incremental.

### Ongoing incremental runs (nightly)

```bash
python pipeline.py
```

Pulls records modified in the last 24 hours. This is what the Azure Functions scheduler calls.

### Verify the load in Snowflake

```sql
-- Check rows landed for a source
SELECT _source_object, COUNT(*) AS row_count, MAX(_extracted_at) AS last_loaded
FROM NS11MM_DW_DEV.RAW.RAW_SALESFORCE_NPS_CONTACT
GROUP BY 1;

-- Check all pipeline runs across all sources
SELECT *
FROM NS11MM_DW_DEV.RAW.PIPELINE_LOG
ORDER BY run_at DESC
LIMIT 50;

-- Inspect a raw record
SELECT _raw_data
FROM NS11MM_DW_DEV.RAW.RAW_SALESFORCE_NPS_CONTACT
LIMIT 1;
```

---

## Shared library

**Never copy shared code into a pipeline folder.** Always import from `shared/`.

```python
from shared.keyvault import secret           # fetch a Key Vault secret by name
from shared.snowflake_client import land_to_bronze, log_run
```

Changes to `shared/` affect all pipelines. Test carefully before merging.

---

## Adding a new pipeline

1. Create a folder: `pipelines/<source_id>/`
2. Add `pipeline.py` using an existing pipeline as a template — only write `authenticate()` and `extract()`
3. Add `requirements.txt` with any source-specific dependencies (most sources need nothing beyond shared)
4. Add credentials to Azure Key Vault (`kv-ns11mm-dp-dev`) — never in code or config files
5. Copy an existing `azure-pipelines-*.yml` from `disabled/`, update the three variables at the top (`FUNCTION_APP_NAME`, source folder name, cron expression), save as `azure-pipelines-<source_id>.yml`, and satisfy the re-enable requirements in `disabled/README.md` before moving it to the repo root
6. Run with `--full` for the initial historical load
7. Confirm rows in `RAW.PIPELINE_LOG` before enabling the nightly schedule

---

## Nightly schedule

All pipelines run between 02:00 and 05:15 AM EST. All times UTC.

| Source | UTC | EST | Function App |
|---|---|---|---|
| Salesforce NPS | 07:00 | 02:00 AM | func-ns11mm-sfnps-dev |
| Salesforce Marketing Cloud | 07:15 | 02:15 AM | func-ns11mm-sfmc-dev |
| Gateway Ticketing | 07:30 | 02:30 AM | func-ns11mm-gateway-dev |
| CounterPoint POS | 07:45 | 02:45 AM | func-ns11mm-counterpoint-dev |
| Shopify | 08:00 | 03:00 AM | func-ns11mm-shopify-dev |
| Classy | 08:15 | 03:15 AM | func-ns11mm-classy-dev |
| Blackbaud NXT | 08:30 | 03:30 AM | func-ns11mm-blackbaud-dev |
| Vena | 08:45 | 03:45 AM | func-ns11mm-vena-dev |
| GA4 | 09:00 | 04:00 AM | func-ns11mm-ga4-dev |
| Google Ads | 09:15 | 04:15 AM | func-ns11mm-googleads-dev |
| Meta Ads | 09:30 | 04:30 AM | func-ns11mm-metaads-dev |
| Wufoo | 09:45 | 04:45 AM | func-ns11mm-wufoo-dev |
| Clicky | 10:00 | 05:00 AM | func-ns11mm-clicky-dev |
| Drupal | 10:15 | 05:15 AM | func-ns11mm-drupal-dev |
| **dbt run** | **11:00** | **06:00 AM** | runs after all RAW loads complete |

---

## Credentials

All credentials are stored in Azure Key Vault (`kv-ns11mm-dp-dev`). No credentials appear in code, config files, or this README.

Secret naming convention: `<SOURCEID>-<CREDENTIAL>` in uppercase with hyphens.
Example: `SFMC-CLIENT-ID`, `SHOPIFY-ACCESS-TOKEN`, `SNOWFLAKE-PASSWORD`

Snowflake credentials (`SNOWFLAKE-ACCOUNT`, `SNOWFLAKE-USER`, `SNOWFLAKE-PASSWORD`) are shared across all pipelines and stored once.

---

## Sources with outstanding setup items

| Source | Blocker |
|---|---|
| Vena | `MODELS` dict in `pipeline.py` is empty — confirm model IDs with Finance team before first run |
| Drupal | `CONTENT_TYPES` list is empty — confirm scope with Anna Kim; path decision (DB vs API) needs an ADR |
| Blackbaud NXT | Registered app must be approved by Blackbaud Admin; refresh token rotation requires Key Vault write access on Function App identity (coordinate with Kenny) |
| Gateway / CounterPoint | Run via self-hosted agent on internal network, not Azure Functions — coordinate VM setup separately with Kenny |

---

## Key contacts

| Area | Contact |
|---|---|
| Pipeline development | Kalea Ramsey / Phinn |
| Azure infrastructure (Key Vault, Function Apps) | Kenny |
| Data platform ownership | Jeremy Myers |
| Salesforce NPS / Marketing Cloud | Salesforce Admin |
| Shopify / Digital sources (GA4, Ads, Wufoo, Clicky, Drupal) | Anna Kim |
| Fundraising (Classy) | Jan-Michael Llanes |
| Finance (Vena, Blackbaud) | Finance team |
| Ticketing / POS (Gateway, CounterPoint) | Kenny / IT |

---

*NS11MM Data Platform — updated June 2026*
