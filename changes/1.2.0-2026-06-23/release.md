# 1.2.0

- **Date:** 2026-06-23
- **Version:** 1.2.0

*Errata (2026-07-29): duplicate version number — this is the first (earlier) 1.2.0, dated 2026-06-23. A second 1.2.0 dated 2026-06-25 appears above. Entries are kept as written — disambiguate by date.*

## dbt Platform Foundation — POC Migration Scaffolding

119 files added establishing the complete dbt project structure for the production platform. All files are either fully production-ready or structured stubs awaiting RAW data connection. No files from this release require logic changes — only field name confirmation once Bronze ingestion is live.

### Project configuration

- `dbt_project.yml` — production configuration: project name `ns11mm_data_platform`, all schema targets (RAW, SILVER, GOLD, ML_FEATURES), query tags, pre-hooks, materialization strategies, and post-hooks granting POWERBI_ROLE and ML_ROLE on Gold models
- `packages.yml` — `dbt_utils` and `dbt_date` package dependencies
- `.gitignore` — standard dbt ignores including `profiles.yml`, `dbt.log`, `graph.gpickle`
- `.sqlfluff` / `.sqlfluffignore` — Snowflake dialect linting, 120-char limit, macros excluded
- `CODEOWNERS` — Jeremy as primary owner; Kalea co-owner on `models/staging/` and `models/silver/`
- `CONTRIBUTING.md` — full developer workflow: environment architecture, local setup, profiles template, change gate classification (Tier 1/2/Emergency), PR checklist, VQR workflow
- `RUNBOOK.md` — daily health check queries, pipeline and dbt failure response, contacts, quick reference command table
- `SNOWFLAKE_SETTINGS.md` — complete inventory of databases, schemas, roles, warehouses, resource monitors, and integrations

### Models — Staging (24 files)

- `models/staging/sources.yml` — all 14 source definitions with freshness thresholds; activate per source as RAW tables are populated
- 23 staging model shells covering all 14 sources: Salesforce NPS (4 objects), Salesforce MC, Gateway (2 objects), CounterPoint (2 objects), Shopify (3 objects), Classy (2 objects), Blackbaud (2 objects), Vena, GA4, Google Ads, Meta Ads, Wufoo, Clicky, Drupal. Each model has the correct VARIANT extraction structure (`_raw_data:<Field>::<TYPE>`), hashdiff generation, and a TODO comment pointing to the exact `SELECT _raw_data ... LIMIT 1` query needed to confirm field names

### Models — Gold Dimensions (11 files)

- `dim_date.sql` — **fully active**: complete date dimension spanning 2000–2035 with NS11MM fiscal calendar (Oct 1–Sep 30), weekend flags, and `is_commemoration_day` flag for September 11 anomaly handling
- `dim_marketing_channel.sql` — **fully active**: seed-based channel dimension; no RAW dependency
- 8 dimension placeholder stubs (`dim_customer`, `dim_gate`, `dim_campaign`, `dim_ticket_type`, `dim_product`, `dim_payment_method`, `dim_fund`, `dim_budget_version`) — correct config and schema entry; replace `select null where 1=0` body with POC logic once Silver is live
- `schema.yml` — full dimension documentation and tests including `is_commemoration_day` description

### Macros — Generic Tests (10 files)

- `test_hashdiff_integrity.sql` — null hash detection and hash collision check
- `test_referential_integrity.sql` — reusable FK validation
- `test_row_count_drift.sql` — zero-row alert
- `test_late_arriving_data.sql` — configurable lag threshold (default 72h)
- `test_schema_drift.sql` — expected vs actual column comparison
- `null_rate_threshold.sql` — configurable null rate ceiling (default 50%)
- `daily_volume_bounds.sql` — min/max row count per day
- `cardinality_change.sql` — distinct value range check
- `distribution_shift.sql` — value frequency drift detection
- `README.md`

### Macros — Data Quality (5 files)

- `generate_hashdiff.sql` — MD5 over business columns with null-safe concatenation
- `quarantine_failed_rows.sql` — routes failed rows to `SILVER.QUARANTINE_LOG`
- `auto_heal_duplicates.sql` — CTE deduplication keeping latest row by primary key
- `check_source_freshness.sql` — per-source staleness thresholds for all 13 API sources; called in on-run-start
- `README.md`

### Macros — Operations (8 files)

- `create_ticket_demand_forecast.sql` — creates Snowflake ML FORECAST model for 90-day multi-series ticket demand; `dbt run-operation create_ticket_demand_forecast`
- `sync_verified_queries.sql` — lists and validates all VQRs; `dbt run-operation sync_verified_queries`
- `validate_before_deploy.sql` — compares dev/prod row counts for 10 key models before deployment
- `compare_model_to_prod.sql` — deep single-model MINUS diff between dev and prod; flags data loss risk
- `smart_retry.sql` — reads audit log, identifies failed models, suggests rerun commands
- `rerun_from_source.sql` — maps RAW source table to downstream dbt models; source map covers all 14 sources
- `resolve_quarantine.sql` — marks quarantine records resolved after successful rerun
- `README.md`

### Macros — Root (1 file)

- `generate_schema_name.sql` — standard dbt schema name override macro

### Tests (16 files)

All reconciliation and referential integrity tests are written and commented out pending production model availability. One test is immediately active:

- `tests/business_rules/assert_date_coverage.sql` — **active now**: validates `dim_date` spans 2000-01-01 through 2035-12-31

Commented-out tests (uncomment as each layer becomes available):
- `tests/reconciliation/` — 4 tests: RAW→Silver count matches for tickets and retail; Silver→Gold revenue and visitor reconciliation
- `tests/referential_integrity/` — 5 tests: campaign FK, ticket type seed match, payment method seed match, customer segment seed match, date orphan check
- `tests/business_rules/` — 3 additional tests: no negative revenue, no future transactions, campaign rates in bounds
- All `README.md` files

### Seeds (5 files)

All reference data seeds — no mock/POC data included:

- `ref_marketing_channels.csv` — 7 channels (Paid Search, Paid Social Facebook/Instagram, Organic, Email, Direct, Referral)
- `ref_ltv_tiers.csv` — Platinum/Gold/Silver/Bronze with thresholds
- `ref_ticket_types.csv` — 10 ticket types matching Gateway taxonomy (Adult/Child/Senior GA, Member, Group, School, Military, First Responder)
- `ref_payment_methods.csv` — 8 payment methods including digital wallets
- `ref_customer_segments.csv` — Known Member / Identified Visitor / Anonymous

### Snapshots (2 files)

- `snap_dim_customer.sql` — SCD Type 2 on customer dimension; check strategy on segment, membership_status, email, phone; commented out pending dim_customer
- `snap_sf_crm.sql` — SCD Type 2 on Salesforce NPS contacts via hashdiff; commented out pending staging model

### CI/CD (1 file)

- `.github/workflows/dbt-ci.yml` — slim CI on PRs (state:modified+ with defer); full build on merge to main; manifest artifact upload for state comparison; dbt docs generation on merge

### Governance documentation (7 files)

- `docs/architecture/SQL_STYLE_GUIDE.md` — naming conventions, layering rules, VARIANT extraction pattern, formatting standards, testing requirements
- `docs/architecture/DATA_CLASSIFICATION.md` — PII field inventory across all 14 sources, access control tiers, new model classification checklist
- `docs/architecture/USAGE_AUDIT.md` — Snowflake query history monitoring, Cortex Agent observability, pipeline log queries, credit monitoring
- `docs/business/METRIC_GLOSSARY.md` — certified metric definitions across 6 domains: Attendance, Revenue, Membership, Fundraising, Digital/Marketing, Flags (including `is_commemoration_day`)
- `docs/adr/0005-metric-definition-gate.md` — metric approval required before Gold model build
- `docs/adr/0006-change-management-tiers.md` — Tier 1/2/Emergency framework
- `docs/adr/0007-drupal-ingestion-path.md` — **decision required**: DB vs JSON:API; unblocks `stg_drupal__pages.sql`
- `docs/adr/0008-retail-source-split.md` — **decision required**: unified vs separate retail fact; recommendation is unified with channel flag (Option A)

### Model groups and exposures (2 files)

- `models/groups.yml` — 6 groups (staging, silver, gold_dimensions, gold_facts, gold_reports, ml_features) with owner emails
- `models/exposures.yml` — 5 exposures: Power BI operations dashboard, Power BI donor retention dashboard, Cortex Analyst operations, ML donor churn model, ML ticket demand forecast

### Terraform / IaC (16 files)

- `terraform/main.tf` — root module orchestrating 4 sub-modules
- `terraform/variables.tf` / `outputs.tf` / `providers.tf` — standard configuration
- `terraform/modules/key-vault/main.tf` — RBAC-based Key Vault with soft-delete and purge protection; admin and pipeline SP role assignments
- `terraform/modules/snowflake-warehouse/main.tf` — warehouse + resource monitor with credit quota
- `terraform/modules/static-web-app/main.tf` — dbt docs hosting
- `terraform/modules/monitor-alerts/main.tf` — Teams webhook + email alert action group
- `terraform/environments/dev.tfvars.json` — X-Small warehouse, 5 credits, `kv-ns11mm-dp-dev`
- `terraform/environments/staging.tfvars.json` — Medium warehouse, 25 credits
- `terraform/environments/prod.tfvars.json` — Medium warehouse, 50 credits
- `terraform/pipelines/deploy-dev.yml` — auto-trigger on main merge
- `terraform/pipelines/deploy-staging.yml` — manual trigger
- `terraform/pipelines/deploy-prod.yml` — manual trigger + ManualValidation approval gate
- `terraform/README.md` / `.gitignore`

### Scripts (1 file)

- `scripts/setup_developer_workspace.sql` — provisions personal dev database for a new team member; creates RAW/SILVER/GOLD/ML_FEATURES schemas, grants TRANSFORMER_ROLE and LOADER_ROLE access, creates audit log table. Includes commented examples for JMYERS, KRAMSEY, DIANA.

### POC migration inventory

- `NS11MM_POC_Migration_Inventory.md` — complete inventory of all 247 POC artifacts with status: 66 complete, 44 awaiting data feed, 109 to migrate from POC with find-and-replace, 10 to rebuild, 1 pending decision, 6 excluded. Includes sequenced "what to do next" and find-and-replace table for all naming changes.

### Outstanding items from this release

| Item | Owner | Blocks |
|---|---|---|
| ADR-007: Drupal path decision | Jeremy + Anna Kim + Kenny | `stg_drupal__pages.sql` completion |
| ADR-008: Retail source split decision | Jeremy | `silver_pos_retail.sql`, `fct_retail_line_items.sql` |
| Migrate 36 verified queries from POC | Kalea | Cortex Analyst activation |
| Migrate `docs/ONBOARDING.md` and `docs/README.md` from POC | Jeremy | Onboarding |
| Migrate `terraform/notifications/teams_webhook_setup.sql` from POC | Kenny | Credit alerts |
| Complete remaining 109 POC file migrations (Silver, Gold, ML, VQRs) | Kalea / Phinn | Gold layer activation |

---
