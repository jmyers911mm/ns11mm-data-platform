# Snowflake Settings — NS11MM Data Platform

> Last updated: June 25, 2026

## Databases

| Database | Purpose | Owner |
|---|---|---|
| `NS11MM_DW_DEV` | Shared dev — promotion target; hosts RAW ingestion + deployed dbt project | ACCOUNTADMIN |
| `NS11MM_DW_DEV_JMYERS` | Jeremy personal dev sandbox (TRANSFORMER_ROLE writes here) | ACCOUNTADMIN |
| `NS11MM_DW_PROD` | Production — Power BI reads from here | ACCOUNTADMIN |

## Schemas (consistent across DEV and PROD)

| Schema | Purpose | dbt folder |
|---|---|---|
| `RAW` | Immutable raw data + `_extracted_at` load timestamp — append-only | (not dbt-managed) |
| `STAGING` | Cleansed/standardized views (`stg_*`) — rename, cast, deduplicate | `models/raw/` |
| `INTERMEDIATE` | Silver incremental models (`silver_*`) — business logic, joins | `models/intermediate/` |
| `MARTS` | Gold dimensions, facts, reports (`dim_*`, `fct_*`, `rpt_*`) | `models/marts/` |
| `ML_FEATURES` | ML feature tables for model training and inference | `models/ml_features/` |
| `MONITORING` | Alerts, tasks, audit views (DEV only) | (not dbt-managed) |

## Roles

| Role | Access | Used by | Hierarchy |
|---|---|---|---|
| `ACCOUNTADMIN` | Full account admin | Jeremy (emergency only) | Top |
| `DEPLOY_PROD_ROLE` | Write to NS11MM_DW_PROD | Jeremy only | ↑ SYSADMIN |
| `DEPLOY_DEV_ROLE` | Write to NS11MM_DW_DEV | Jeremy only | ↑ DEPLOY_PROD_ROLE |
| `TRANSFORMER_ROLE` | Write to personal dev DB only; read NS11MM_DW_DEV | All developers | ↑ DEPLOY_DEV_ROLE |
| `LOADER_ROLE` | Write to RAW schema (DEV + PROD) | Pipeline service account | Standalone |
| `POWERBI_ROLE` | SELECT on MARTS (PROD) | Power BI gateway + AGORDON | Standalone |
| `ML_ROLE` | SELECT INTERMEDIATE + MARTS; WRITE ML_FEATURES | ML workflows | Standalone |

## Warehouses

| Warehouse | Size | Auto-suspend | Timeout | Used by |
|---|---|---|---|---|
| `COMPUTE_WH` | Small | 60s | 30 min | General / ad-hoc |
| `DBT_DEV_WH` | X-Small | 30s | 15 min | dbt dev builds (TRANSFORMER_ROLE) |
| `DBT_PROD_WH` | Small | 60s | 30 min | dbt prod builds (DEPLOY_PROD_ROLE) + Power BI |
| `SOURCES_WH` | X-Small | 30s | 15 min | Pipeline ingestion (LOADER_ROLE) |
| `MONITORING_WH` | X-Small | 30s | 5 min | Alerts, tasks, freshness checks |
| `ML_STUDIO_WH` | Small | 60s | 60 min | ML training (ML_ROLE) |

## Resource Monitors

| Monitor | Warehouse | Limit | Notify/Suspend |
|---|---|---|---|
| `DBT_DEV_MONITOR` | DBT_DEV_WH | 5 credits/month | 75% / 90% / 100% |
| `DBT_PROD_MONITOR` | DBT_PROD_WH | 50 credits/month | 75% / 90% / 100% |
| `ML_STUDIO_MONITOR` | ML_STUDIO_WH | 30 credits/month | 75% / 90% / 100% |
| `MONITORING_WH_MONITOR` | MONITORING_WH | 20 credits/month | 75% / 90% / 100% |
| `SOURCES_MONITOR` | (account-level) | 75 credits/month | 75% / 90% / 100% |
| `TRANSFORM_WH_MONITOR` | TRANSFORM_WH | 100 credits/month | 75% / 90% / 100% |

## Alerts (NS11MM_DW_DEV.MONITORING)

| Alert | Schedule | Triggers |
|---|---|---|
| `ALERT_SOURCE_FRESHNESS` | 60 min | RAW table not updated in 6+ hours |
| `ALERT_DBT_RUN_FAILURES` | 30 min | dbt-tagged query fails |
| `ALERT_WAREHOUSE_UTILIZATION` | 120 min | Queries queuing (overloaded WH) |
| `ALERT_CREDIT_CONSUMPTION` | Daily | >10 credits in 24 hours |
| `ALERT_LONG_RUNNING_QUERIES` | 60 min | Any query >10 minutes |

## Tasks (NS11MM_DW_DEV.MONITORING)

| Task | Schedule | Purpose |
|---|---|---|
| `TASK_DAILY_DBT_BUILD` | 6 AM ET daily | EXECUTE DBT PROJECT (full build) |
| `TASK_DAILY_FRESHNESS_CHECK` | 5:30 AM ET daily | Pre-build RAW freshness validation |
| `TASK_WEEKLY_PROD_CLONE` | 2 AM ET Sundays | Zero-copy clone NS11MM_DW_PROD → NS11MM_DW_PROD_BACKUP |
| `TASK_WEEKLY_DOCS_GENERATE` | 7 AM ET Mondays | dbt docs generate |

## Notification Integrations

| Integration | Type | Recipients |
|---|---|---|
| `NS11MM_DATAAI_EMAIL` | Email | jmyers@911memorial.org |
| `NS11MM_TASK_ERRORS` | Email | jmyers@911memorial.org |
| `MUSEUM_DW_EMAIL_ALERTS` | Email | jmyers@911memorial.org |

## Security Policies

| Policy | Type | Location | Purpose |
|---|---|---|---|
| `MASK_NAME` | Masking | DEV + PROD PUBLIC | Masks name columns for non-privileged roles |
| `MASK_EMAIL` | Masking | DEV + PROD PUBLIC | Partially masks email (***@domain.com) |
| `MASK_PHONE` | Masking | DEV + PROD PUBLIC | Shows last 4 digits only |
| `RAP_PII_ACCESS` | Row Access | DEV + PROD PUBLIC | ML_ROLE cannot see rows with PII |
| `NS11MM_NETWORK_POLICY` | Network | Account-level (NOT activated) | IP allowlist for known office/Azure IPs |

## Tags

| Tag | Allowed Values | Purpose |
|---|---|---|
| `SENSITIVITY` | PII, INTERNAL, PUBLIC, CONFIDENTIAL | Data classification |
| `DATA_DOMAIN` | TICKETING, CRM, MARKETING, RETAIL, FUNDRAISING, FINANCE, WEB_ANALYTICS | Business domain |
| `DATA_OWNER` | (freeform) | Responsible person/team |

## Data Metric Functions (NS11MM_DW_DEV.MONITORING)

| DMF | Returns | Purpose |
|---|---|---|
| `DMF_NULL_RATE` | % (0-100) | Null rate for any VARCHAR column |
| `DMF_ROW_COUNT` | Integer | Total row count — detect drops |
| `DMF_DUPLICATE_RATE` | % (0-100) | Duplicate rate — 0 = all unique |
| `DMF_FRESHNESS_HOURS` | Hours | Hours since max timestamp value |

## Secrets

| Secret | Type | Purpose |
|---|---|---|
| `SECRET_POWERBI_SVC` | Password | Power BI service account (rotate immediately) |
| `SECRET_LOADER_SVC` | Password | Pipeline loader (rotate immediately) |

## dbt Project Object

| Object | FQN | Default Target |
|---|---|---|
| Deployed dbt project | `NS11MM_DW_DEV.PUBLIC.NS11MM_DATA_PLATFORM` | `dev_shared` |
