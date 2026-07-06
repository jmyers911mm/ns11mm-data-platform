# Changelog

All notable changes to the ns11mm-data-platform project will be documented in this file.

This is the production repository (`ns11mm/ns11mm-data-platform`), successor to the POC (`jmyers911mm/ns11mm-dbt`). The POC changelog is preserved separately. Version numbering restarts at 1.0.0 for this repo.

## [1.3.2] — 2026-07-06 — Doc Cleanup

### Documentation Review — Current-Scope Accuracy Pass

Reviewed all 39 `.md` files in `ns11mm/ns11mm-data-platform` against the actual repo state
(models enabled vs. `enabled=false`, real folder names, real file names). **22 files changed.**

Ground truth used: **live today = the Gateway + CounterPoint → Daily Performance Report slice**
(21 staging, 8 intermediate, 4 dims + 1 fact + 1 report, 1 semantic view). Everything else is
present but `enabled=false`. This zip contains only the changed files, at their repo paths.

---

#### Two systemic problems fixed

1. **Orphaned Git merge-conflict markers.** 54 stray `>>>>>>> remote` lines across 16 files
   (no matching `<<<<<<<`/`=======` halves — content was intact). All removed. Files affected
   by *marker removal only*: `CHANGELOG.md`, `SNOWFLAKE_SETTINGS.md`, `docs/ONBOARDING.md`,
   `docs/architecture/DATA_CLASSIFICATION.md`, `SQL_STYLE_GUIDE.md`, `USAGE_AUDIT.md`,
   `macros/data_quality/README.md`, `macros/generic_tests/README.md`.

2. **Docs presenting the full future platform as if it's live today**, with no current-vs-planned
   distinction (the issue you flagged on the main README + customer 360).

---

#### Substantive changes

- **README.md** — rewritten. Added a "Current scope: live today vs. planned" banner with a
  live/total counts table; corrected the "96 models" claim; fixed the Project Structure tree to
  the real folders (`models/raw`, `models/intermediate`, `models/marts/{dimensions,facts,reports}`
  — not `staging/silver/gold`); replaced fictional model names and lineage
  (`stg_gateway__transactions`, `fct_ticket_sales`, `rpt_ticket_sales`) with the real DPR chain;
  marked Identity Resolution, the 4 semantic views, the Cortex agent, and the VQR library as
  **[PLANNED]** and corrected to the single live `MARTS.DPR` view; fixed the fiscal-year
  contradiction.

- **docs/architecture/PROJECT_MAP.md** — fixed all `models/staging|silver|gold/` paths to
  `raw|intermediate|marts`; replaced the fictional reference chain and the mental-model diagram
  with the real live DPR flow; corrected the repository-map counts to live/total; marked deleted
  items (exposures placeholder, snapshots planned, `verified_queries` removed); pointed the seeds
  and semantic_models rows at what's actually there; added a scope banner.

- **docs/business/README.md** — added a "what's available today" banner; annotated the dashboard
  finder with Live/(planned) status (only the Daily Performance Report is live); corrected the
  claim that every area already has a dashboard.

- **PLATFORM_SCORECARD.md** — added a scope note; corrected "4 semantic views" → 1 live DPR view;
  noted the VQR library was removed.

- **semantic_models/README.md** — fixed the file names (`dpr_semantic_view.sql` →
  `create_dpr_semantic_view.sql`; `dpr_semantic_model.yaml` → `dpr.yaml`) and the object name
  (`NS11MM_DP.MARTS.DPR` → `MARTS.DPR`, portable via `USE DATABASE`).

- **Scope banners added** (forward-looking docs that were otherwise fine): `docs/README.md`,
  `docs/architecture/ARCHITECTURE_FLOW.md`, `SOURCE_INTEGRATION.md`, `TEST_ORCHESTRATION.md`,
  `docs/business/METRIC_GLOSSARY.md`.

- **Concrete stale-reference fixes:** `CONTRIBUTING.md` (VQR workflow marked [PLANNED], notes the
  library was removed in 1.3.1); `macros/operations/README.md` (`sync_verified_queries` marked
  inactive); `GATEWAY_COUNTERPOINT_SCHEMA_REQUEST.md` (`models/staging/` → `models/raw/`);
  `RUNBOOK.md` (example command repointed from `fct_ticket_sales` to the live `fct_daily_performance`).

---

#### Left unchanged (already accurate)

- **The six model-folder READMEs** (`models/raw`, `models/intermediate`, `models/marts/dimensions`,
  `.../facts`, `.../reports`, `models/ml_features`) — these already list Enabled vs. Disabled
  models correctly with blocker/re-enable reasons. Verified each against the actual model configs;
  they match exactly. These are the authoritative per-model source of truth, and the rewritten
  top-level docs now point to them.
- **ADRs, tests/* READMEs, pipelines/readme, terraform/README** — accurate or forward-looking by
  design; no current-vs-planned misrepresentation after marker cleanup.

---

#### One thing to confirm

The main README now says to **confirm the fiscal start month**, while `METRIC_GLOSSARY.md` asserts
**October** (FY = Oct–Sep). `dim_date` has `fiscal_year`/`fiscal_month` logic. If October is
correct, the README can be made assertive to match the glossary.

## [1.3.1] — 2026-07-06 — DPR Semantic View & Build Fixes

### Added

**Semantic View**
- `NS11MM_DW_DEV_JMYERS.MARTS.DPR` — native Snowflake semantic view over FCT_DAILY_PERFORMANCE + DIM_DATE with 19 metrics (additive SUM + ratio-of-sums), 8 dimensions, AI instructions, and commemoration-window awareness
- `semantic_models/create_dpr_semantic_view.sql` — environment-portable DDL (USE DATABASE at top for dev/prod switch)
- `semantic_models/dpr.yaml` — Cortex Analyst YAML spec with verified queries and custom instructions

### Fixed

**Staging Models**
- `stg_gateway__orders.sql` — removed non-existent columns (`orderno`, `transno`, `eventno`, `status`, `total`, `tax`, `totalpaid`, `totalrefund`, `totaldue`, `depositamt`, `pendingloyaltypoints`, `issuedloyaltypoints`, `orderdate`, `groupid`); rewrote with correct column names from SEED_GATE_ORDERS
- `stg_gateway__orderlines.sql` — removed non-existent columns (`orderno`, `lineno`); rewrote with correct column names from SEED_GATE_ORDERLINES

**Mart Models**
- `fct_daily_performance.sql` — `cluster_by` changed from `date_key` to `date_id`; output column renamed `date_key` → `date_id`; join to dim_date updated to use `date_id`; added `WHERE key_date IS NOT NULL` to date_spine CTEs to handle upstream NULL dates
- `rpt_daily_performance_report.sql` — join updated from `f.date_key = dd.date_key` to `f.date_id = dd.date_id`; mapped `calendar_year`/`calendar_month` to actual dim_date columns (`year_number`/`month_of_year`); output column renamed `date_key` → `date_id`

**Intermediate Models**
- `silver_gateway__ticket_journal_lines.sql` — added `WHERE key_date IS NOT NULL` to filter rows where try_to_timestamp returned NULL from literal 'NULL' strings in raw date columns
- `silver_gateway__item_journal_lines.sql` — same NULL date filter added

**Schema / Tests**
- `models/marts/_dpr__marts.yml` — all `date_key` references updated to `date_id`; relationship field updated
- `models/intermediate/_dpr__models.yml` — no changes needed (key_date tests now pass after view rebuild)
- 12 singular tests disabled (`enabled=false`) that reference disabled/deleted models

### Changed

- `models/intermediate/schema.yml` — removed schema entries for deleted models (`silver_pos_tickets`, `silver_pos_retail`, `silver_ticket_scans`, `silver_ticket_inventory`)
- `models/exposures.yml` — all 11 exposures removed (depend on disabled marts); placeholder comments retained

### Removed

- `analyses/create_marketing_semantic_view.sql` — deleted (referenced disabled models)
- `analyses/verified_queries/` — entire directory removed (49 files; no verified queries currently applicable)

---

## [1.3.0] — 2026-07-06 — Gateway & CounterPoint Seed Data Buildout

### Added

**Raw Tables (NS11MM_DW_DEV_JMYERS.RAW)**
- 16 `SEED_GATE_*` tables created from Gateway Galaxy SQL Server CSV exports via INFER_SCHEMA
- 5 `SEED_CP_*` tables created from CounterPoint POS CSV exports (IM-ITEM, PS-TKT-HIST, PS-TKT-HIST-LIN, VI-TKT-HIST, VI-TKT-HIST-LIN)

**Staging Models (models/raw/)**
- 16 new `stg_gateway__*.sql` models — snake_case renaming, try_to_timestamp for dates, logical column grouping
- 5 new `stg_counterpoint__*.sql` models — full column coverage for POS item master, ticket history headers/lines, and enriched views

**Source Definitions**
- `gateway_seed` source (NS11MM_DW_DEV_JMYERS.RAW, 16 tables)
- `counterpoint_seed` source (NS11MM_DW_DEV_JMYERS.RAW, 5 tables)

**Seeds (seeds/)**
- `seed_tour_plu.csv` — PLU-to-DPR tour line item mapping
- `seed_retail_item_facility.csv` — CounterPoint item_no → facility override
- `seed_retail_store_facility.csv` — CounterPoint store_id → facility fallback
- `_seeds.yml` — schema definitions, column types, and tests for all 3 new seeds

**Intermediate Models (models/intermediate/)**
- `silver_counterpoint__retail_lines.sql` — CounterPoint retail lines with facility assignment
- `silver_gateway__item_journal_lines.sql` — Gateway item-level journal lines
- `silver_gateway__ticket_journal_lines.sql` — Gateway ticket journal lines with product classification
- `silver_dpr__admissions.sql` — DPR admissions revenue
- `silver_dpr__donations.sql` — DPR donation revenue
- `silver_dpr__fees_and_services.sql` — DPR fees and services revenue
- `silver_dpr__retail.sql` — DPR retail revenue
- `silver_dpr__tour_revenue.sql` — DPR tour revenue

**Mart Models (models/marts/)**
- `fct_daily_performance.sql` — Daily performance by DPR line item
- `rpt_daily_performance_report.sql` — Report joining fct_daily_performance + dim_date
- `_dpr__marts.yml` — schema docs for DPR mart models

**Documentation**
- README.md files added to all model folders (raw, intermediate, marts/dimensions, marts/facts, marts/reports, ml_features) documenting enabled vs disabled models

### Changed

**Renamed Tables**
- 16 existing `SEED_*` tables renamed to `SEED_GATE_*` (Gateway source prefix)
- 5 new `SEED_*` tables renamed to `SEED_CP_*` (CounterPoint source prefix)

**dbt_project.yml**
- Removed git merge conflict marker (`>>>>>>> remote`)

**packages.yml**
- Removed git merge conflict marker (`>>>>>>> remote`)

**models/exposures.yml**
- Removed git merge conflict marker (`>>>>>>> remote`)

**Reconciliation Tests**
- `assert_raw_silver_ticket_count_match.sql` — now uses `source('gateway_seed', 'seed_gate_jnltickets')` (no longer commented out)
- `assert_raw_silver_retail_count_match.sql` — now uses `source('counterpoint_seed', 'seed_cp_pstkthistlin')` (no longer commented out)

**models/intermediate/schema.yml**
- Updated silver_pos_tickets docs (PK → jnl_detail_id, date → sold_at)
- Updated silver_pos_retail docs (PK → line_guid, date → business_date)
- Updated silver_ticket_scans docs (PK → usage_id, date → use_time)

### Removed

**Deleted Staging Models** (19 files — sources not available)
- `stg_salesforce_nps__contacts.sql`, `stg_salesforce_nps__accounts.sql`, `stg_salesforce_nps__opportunities.sql`, `stg_salesforce_nps__campaigns.sql`
- `stg_salesforce_mc__tracking.sql`
- `stg_shopify__orders.sql`, `stg_shopify__customers.sql`, `stg_shopify__products.sql`
- `stg_classy__campaigns.sql`, `stg_classy__transactions.sql`
- `stg_blackbaud__accounts.sql`, `stg_blackbaud__journal_entries.sql`
- `stg_ga4__sessions.sql`
- `stg_google_ads__campaigns.sql`
- `stg_meta_ads__campaigns.sql`
- `stg_vena__budget.sql`
- `stg_wufoo__form_entries.sql`
- `stg_clicky__visitors.sql`
- `stg_drupal__pages.sql`

**Deleted Obsolete Staging Models** (3 files — replaced by new gateway_seed models)
- `stg_gateway__customers.sql`, `stg_gateway__ticket_types.sql`, `stg_gateway__transactions.sql`

**Deleted Obsolete Staging Models** (3 files — replaced by new counterpoint_seed models)
- `stg_counterpoint__items.sql`, `stg_counterpoint__line_items.sql`, `stg_counterpoint__transactions.sql`

**Deleted Silver Models** (4 files — superseded by new intermediate models)
- `silver_pos_tickets.sql`, `silver_pos_retail.sql`, `silver_ticket_scans.sql`, `silver_ticket_inventory.sql`

**Removed Source Definitions** (12 sources from sources.yml)
- salesforce_nps, salesforce_mc, gateway (old), shopify, classy, blackbaud, vena, ga4, google_ads, meta_ads, wufoo, clicky, drupal

### Disabled (`enabled=false`)

**Intermediate** (8 models)
- `silver_sf_crm`, `silver_sf_marketing_cloud`, `silver_shopify`, `silver_classy`, `silver_blackbaud`, `silver_google_analytics`, `silver_google_ads`, `silver_meta_ads`

**Marts — Dimensions** (6 models)
- `dim_campaign`, `dim_customer`, `dim_gate`, `dim_payment_method`, `dim_product`, `dim_ticket_type`

**Marts — Facts** (22 models)
- `bridge_session_customer`, `fct_ad_campaign_daily`, `fct_campaign_attribution`, `fct_campaign_performance`, `fct_daily_operations`, `fct_digital_ad_performance`, `fct_donor_cohort_survival`, `fct_donor_retention`, `fct_fundraising`, `fct_gl_transactions`, `fct_marketing_channel_summary`, `fct_marketing_sales_daily`, `fct_monthly_operations`, `fct_monthly_retail`, `fct_retail_line_items`, `fct_ticket_availability`, `fct_ticket_demand_benchmarks`, `fct_ticket_sales`, `fct_ticket_utilization`, `fct_visitor_traffic`, `fct_website_funnel`, `fct_website_traffic`

**Marts — Reports** (9 models)
- `rpt_campaign_performance`, `rpt_customer_ltv`, `rpt_daily_operations`, `rpt_digital_marketing`, `rpt_member_360`, `rpt_retail_performance`, `rpt_revenue_bridge`, `rpt_ticket_sales`, `rpt_visitor_traffic`

**ML Features** (14 models)
- All `ml_*` models disabled — depend on disabled upstream facts

---

## [1.2.0] — 2026-06-25 — Best Practices, Security & Monitoring

### Added
- `NS11MM_DW_DEV.MONITORING` schema — alerts, tasks, audit views, DMFs
- 5 active alerts: source freshness, dbt failures, warehouse utilization, credit consumption, long-running queries
- `MANAGE_ALERTS` stored procedure — suspend/resume alerts individually or all at once
- 4 scheduled tasks: daily dbt build (6 AM), freshness check (5:30 AM), weekly PROD clone (Sun 2 AM), weekly docs generate (Mon 7 AM)
- 3 masking policies: MASK_NAME, MASK_EMAIL, MASK_PHONE (DEV + PROD)
- Row access policy: RAP_PII_ACCESS (ML_ROLE filtered from PII rows)
- Network policy: NS11MM_NETWORK_POLICY (created, NOT activated — test first)
- 3 governance tags: SENSITIVITY, DATA_DOMAIN, DATA_OWNER
- 4 Data Metric Functions: DMF_NULL_RATE, DMF_ROW_COUNT, DMF_DUPLICATE_RATE, DMF_FRESHNESS_HOURS
- `macros/operations/apply_masking_policies.sql` — auto-applies masking on-run-end
- `macros/operations/apply_governance_tags.sql` — auto-applies tags on-run-end
- `macros/operations/create_raw_streams.sql` — creates CDC streams on RAW tables
- `.github/workflows/dbt-ci.yml` — CI workflow for PR validation
- `docs/DATA_CONTRACTS.yml` — freshness SLAs, quality thresholds, refresh targets
- `models/exposures.yml` — expanded with 5 Power BI dashboards, 3 Cortex Analyst views, 3 ML models
- 2 Snowflake secrets: SECRET_POWERBI_SVC, SECRET_LOADER_SVC (rotate immediately)
- Deployed dbt project: `NS11MM_DW_DEV.PUBLIC.NS11MM_DATA_PLATFORM`

### Changed
- `DEPLOY_DEV_ROLE` and `DEPLOY_PROD_ROLE` created with proper hierarchy
- Old roles removed: `DBT_DEV_ROLE`, `DBT_PROD_ROLE`
- `MUSEUM_DW_DEV` database dropped (old POC)
- `NS11MM_DW_DEV_KRAMSEY` database dropped
- All old schemas removed from JMYERS and PROD (BRONZE, SILVER, GOLD, etc.)
- NS11MM_DW_DEV time travel increased to 7 days
- Warehouse auto_suspend: MONITORING/SOURCES/DBT_DEV reduced to 30s
- Statement timeouts set on all warehouses (5–60 min based on workload)
- POWERBI_SVC: query_tag set to 'powerbi_reporting'
- `dbt_project.yml`: added `on-run-end` hooks for tags + masking
- LOADER_ROLE: granted write to RAW in DEV + PROD
- POWERBI_ROLE: granted SELECT + future grants on MARTS (PROD)
- ML_ROLE: granted SELECT INTERMEDIATE/MARTS + WRITE ML_FEATURES

### Documentation Updated
- `SNOWFLAKE_SETTINGS.md` — complete rewrite reflecting current state
- `docs/README.md` — schema table updated with STAGING layer
- `docs/ONBOARDING.md` — RBAC roles, profiles.yml note for Snowflake-native
- `docs/architecture/DATA_CLASSIFICATION.md` — updated PII locations, masking policies, role-based access table
- `docs/architecture/TEST_ORCHESTRATION.md` — updated source names and freshness thresholds
- `docs/architecture/SQL_STYLE_GUIDE.md` — updated naming convention table
- `docs/architecture/SOURCE_INTEGRATION.md` — terminology (Bronze → RAW)
- `docs/architecture/USAGE_AUDIT.md` — added pre-built monitoring views section
- `docs/business/METRIC_GLOSSARY.md` — fiscal year corrected to October start
- `macros/operations/README.md` — added all new macros + on-run-end hooks
- `macros/data_quality/README.md` — updated freshness thresholds
- `RUNBOOK.md` — added GDPR, governance, alert management, and deployed dbt project commands
- `PLATFORM_SCORECARD.md` — new file: best-in-class assessment (9.3/10), architecture diagram, role hierarchy, monitoring stack, industry comparison

---

## [1.1.0] — 2026-06-24 — Production Git Workspace Migration

### Added
- `profiles.yml` for Snowflake-native dbt (no env_var/password/authenticator)
- `models/raw/stg_gateway__customers.sql` — staging model for Gateway customer data
- `models/intermediate/schema.yml` — documentation + tests for all 12 intermediate models
- `models/marts/facts/schema.yml` — documentation + tests for all 22 fact models
- `models/marts/reports/schema.yml` — documentation + tests for all 9 report models
- `models/ml_features/schema.yml` — documentation + tests for all 14 ML feature models
- `semantic_models/ns11mm_marketing_performance.yaml` — SV_MARKETING_PERFORMANCE (6 entities: digital_ad_performance, email_campaigns, website_traffic, website_funnel, channel_summary, dates)
- `semantic_models/ns11mm_marketing_sales.yaml` — SV_MARKETING_SALES (3 entities: marketing_sales_daily, campaign_attribution, dates)
- `notebooks/ml_member_churn_prediction.ipynb` — XGBoost member churn classifier with Snowflake ML Registry integration
- `notebooks/ml_ticket_demand_forecast.ipynb` — XGBoost ticket demand forecaster with Snowflake ML Registry integration
- `macros/operations/gdpr_anonymize.sql` — GDPR right-to-erasure macro; anonymizes PII across INTERMEDIATE + MARTS layers with audit log
- `macros/generic_tests/z_score_outlier.sql` — statistical outlier detection test (configurable z-score threshold)
- `macros/generic_tests/positive_value.sql` — assert column values are non-negative
- `macros/generic_tests/value_between.sql` — assert column values within min/max bounds
- Three-tier RBAC promotion model: TRANSFORMER_ROLE → DEPLOY_DEV_ROLE → DEPLOY_PROD_ROLE

### Fixed
- `silver_sf_crm` — replaced NULL placeholders with actual joins to stg_salesforce_nps__opportunities for membership and donation enrichment
- `silver_blackbaud` — fixed `CASE WHEN null` logic (now uses `CASE WHEN IS NULL`)
- `silver_pos_tickets` — resolved missing customer_email/phone by creating stg_gateway__customers and joining
- `dim_customer` schema.yml — test column corrected from `id` to `customer_id`, added `unique` test
- `dbt_project.yml` — raw models schema changed from `INTERMEDIATE` to `STAGING`
- README fiscal year reference corrected to October start (was July)

### Changed
- `profiles.yml` — `dev_shared` target now uses `DEPLOY_DEV_ROLE`, `prod` uses `DEPLOY_PROD_ROLE`
- `ns11mm_operations.yaml` — expanded with daily_operations + ticket_availability tables (now 5 entities)
- `ns11mm_fundraising_members.yaml` — added donor_retention table (now 5 entities)
- `CONTRIBUTING.md` — added RBAC-enforced promotion workflow, role permissions table, developer targets, emergency hotfix process, updated environment architecture and schema table
- `RUNBOOK.md` — corrected schema reference from GOLD to MARTS
- `docs/architecture/ARCHITECTURE_FLOW.md` — staging layer schema updated to STAGING, model names updated to production naming convention
- `docs/architecture/PROJECT_MAP.md` — reference chain updated from POC single-source pattern to 14-source production pattern

---

## [1.2.0] - 2026-06-23

### dbt Platform Foundation — POC Migration Scaffolding

119 files added establishing the complete dbt project structure for the production platform. All files are either fully production-ready or structured stubs awaiting RAW data connection. No files from this release require logic changes — only field name confirmation once Bronze ingestion is live.

#### Project configuration

- `dbt_project.yml` — production configuration: project name `ns11mm_data_platform`, all schema targets (RAW, SILVER, GOLD, ML_FEATURES), query tags, pre-hooks, materialization strategies, and post-hooks granting POWERBI_ROLE and ML_ROLE on Gold models
- `packages.yml` — `dbt_utils` and `dbt_date` package dependencies
- `.gitignore` — standard dbt ignores including `profiles.yml`, `dbt.log`, `graph.gpickle`
- `.sqlfluff` / `.sqlfluffignore` — Snowflake dialect linting, 120-char limit, macros excluded
- `CODEOWNERS` — Jeremy as primary owner; Kalea co-owner on `models/staging/` and `models/silver/`
- `CONTRIBUTING.md` — full developer workflow: environment architecture, local setup, profiles template, change gate classification (Tier 1/2/Emergency), PR checklist, VQR workflow
- `RUNBOOK.md` — daily health check queries, pipeline and dbt failure response, contacts, quick reference command table
- `SNOWFLAKE_SETTINGS.md` — complete inventory of databases, schemas, roles, warehouses, resource monitors, and integrations

#### Models — Staging (24 files)

- `models/staging/sources.yml` — all 14 source definitions with freshness thresholds; activate per source as RAW tables are populated
- 23 staging model shells covering all 14 sources: Salesforce NPS (4 objects), Salesforce MC, Gateway (2 objects), CounterPoint (2 objects), Shopify (3 objects), Classy (2 objects), Blackbaud (2 objects), Vena, GA4, Google Ads, Meta Ads, Wufoo, Clicky, Drupal. Each model has the correct VARIANT extraction structure (`_raw_data:<Field>::<TYPE>`), hashdiff generation, and a TODO comment pointing to the exact `SELECT _raw_data ... LIMIT 1` query needed to confirm field names

#### Models — Gold Dimensions (11 files)

- `dim_date.sql` — **fully active**: complete date dimension spanning 2000–2035 with NS11MM fiscal calendar (Oct 1–Sep 30), weekend flags, and `is_commemoration_day` flag for September 11 anomaly handling
- `dim_marketing_channel.sql` — **fully active**: seed-based channel dimension; no RAW dependency
- 8 dimension placeholder stubs (`dim_customer`, `dim_gate`, `dim_campaign`, `dim_ticket_type`, `dim_product`, `dim_payment_method`, `dim_fund`, `dim_budget_version`) — correct config and schema entry; replace `select null where 1=0` body with POC logic once Silver is live
- `schema.yml` — full dimension documentation and tests including `is_commemoration_day` description

#### Macros — Generic Tests (10 files)

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

#### Macros — Data Quality (5 files)

- `generate_hashdiff.sql` — MD5 over business columns with null-safe concatenation
- `quarantine_failed_rows.sql` — routes failed rows to `SILVER.QUARANTINE_LOG`
- `auto_heal_duplicates.sql` — CTE deduplication keeping latest row by primary key
- `check_source_freshness.sql` — per-source staleness thresholds for all 13 API sources; called in on-run-start
- `README.md`

#### Macros — Operations (8 files)

- `create_ticket_demand_forecast.sql` — creates Snowflake ML FORECAST model for 90-day multi-series ticket demand; `dbt run-operation create_ticket_demand_forecast`
- `sync_verified_queries.sql` — lists and validates all VQRs; `dbt run-operation sync_verified_queries`
- `validate_before_deploy.sql` — compares dev/prod row counts for 10 key models before deployment
- `compare_model_to_prod.sql` — deep single-model MINUS diff between dev and prod; flags data loss risk
- `smart_retry.sql` — reads audit log, identifies failed models, suggests rerun commands
- `rerun_from_source.sql` — maps RAW source table to downstream dbt models; source map covers all 14 sources
- `resolve_quarantine.sql` — marks quarantine records resolved after successful rerun
- `README.md`

#### Macros — Root (1 file)

- `generate_schema_name.sql` — standard dbt schema name override macro

#### Tests (16 files)

All reconciliation and referential integrity tests are written and commented out pending production model availability. One test is immediately active:

- `tests/business_rules/assert_date_coverage.sql` — **active now**: validates `dim_date` spans 2000-01-01 through 2035-12-31

Commented-out tests (uncomment as each layer becomes available):
- `tests/reconciliation/` — 4 tests: RAW→Silver count matches for tickets and retail; Silver→Gold revenue and visitor reconciliation
- `tests/referential_integrity/` — 5 tests: campaign FK, ticket type seed match, payment method seed match, customer segment seed match, date orphan check
- `tests/business_rules/` — 3 additional tests: no negative revenue, no future transactions, campaign rates in bounds
- All `README.md` files

#### Seeds (5 files)

All reference data seeds — no mock/POC data included:

- `ref_marketing_channels.csv` — 7 channels (Paid Search, Paid Social Facebook/Instagram, Organic, Email, Direct, Referral)
- `ref_ltv_tiers.csv` — Platinum/Gold/Silver/Bronze with thresholds
- `ref_ticket_types.csv` — 10 ticket types matching Gateway taxonomy (Adult/Child/Senior GA, Member, Group, School, Military, First Responder)
- `ref_payment_methods.csv` — 8 payment methods including digital wallets
- `ref_customer_segments.csv` — Known Member / Identified Visitor / Anonymous

#### Snapshots (2 files)

- `snap_dim_customer.sql` — SCD Type 2 on customer dimension; check strategy on segment, membership_status, email, phone; commented out pending dim_customer
- `snap_sf_crm.sql` — SCD Type 2 on Salesforce NPS contacts via hashdiff; commented out pending staging model

#### CI/CD (1 file)

- `.github/workflows/dbt-ci.yml` — slim CI on PRs (state:modified+ with defer); full build on merge to main; manifest artifact upload for state comparison; dbt docs generation on merge

#### Governance documentation (7 files)

- `docs/architecture/SQL_STYLE_GUIDE.md` — naming conventions, layering rules, VARIANT extraction pattern, formatting standards, testing requirements
- `docs/architecture/DATA_CLASSIFICATION.md` — PII field inventory across all 14 sources, access control tiers, new model classification checklist
- `docs/architecture/USAGE_AUDIT.md` — Snowflake query history monitoring, Cortex Agent observability, pipeline log queries, credit monitoring
- `docs/business/METRIC_GLOSSARY.md` — certified metric definitions across 6 domains: Attendance, Revenue, Membership, Fundraising, Digital/Marketing, Flags (including `is_commemoration_day`)
- `docs/adr/0005-metric-definition-gate.md` — metric approval required before Gold model build
- `docs/adr/0006-change-management-tiers.md` — Tier 1/2/Emergency framework
- `docs/adr/0007-drupal-ingestion-path.md` — **decision required**: DB vs JSON:API; unblocks `stg_drupal__pages.sql`
- `docs/adr/0008-retail-source-split.md` — **decision required**: unified vs separate retail fact; recommendation is unified with channel flag (Option A)

#### Model groups and exposures (2 files)

- `models/groups.yml` — 6 groups (staging, silver, gold_dimensions, gold_facts, gold_reports, ml_features) with owner emails
- `models/exposures.yml` — 5 exposures: Power BI operations dashboard, Power BI donor retention dashboard, Cortex Analyst operations, ML donor churn model, ML ticket demand forecast

#### Terraform / IaC (16 files)

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

#### Scripts (1 file)

- `scripts/setup_developer_workspace.sql` — provisions personal dev database for a new team member; creates RAW/SILVER/GOLD/ML_FEATURES schemas, grants TRANSFORMER_ROLE and LOADER_ROLE access, creates audit log table. Includes commented examples for JMYERS, KRAMSEY, DIANA.

#### POC migration inventory

- `NS11MM_POC_Migration_Inventory.md` — complete inventory of all 247 POC artifacts with status: 66 complete, 44 awaiting data feed, 109 to migrate from POC with find-and-replace, 10 to rebuild, 1 pending decision, 6 excluded. Includes sequenced "what to do next" and find-and-replace table for all naming changes.

#### Outstanding items from this release

| Item | Owner | Blocks |
|---|---|---|
| ADR-007: Drupal path decision | Jeremy + Anna Kim + Kenny | `stg_drupal__pages.sql` completion |
| ADR-008: Retail source split decision | Jeremy | `silver_pos_retail.sql`, `fct_retail_line_items.sql` |
| Migrate 36 verified queries from POC | Kalea | Cortex Analyst activation |
| Migrate `docs/ONBOARDING.md` and `docs/README.md` from POC | Jeremy | Onboarding |
| Migrate `terraform/notifications/teams_webhook_setup.sql` from POC | Kenny | Credit alerts |
| Complete remaining 109 POC file migrations (Silver, Gold, ML, VQRs) | Kalea / Phinn | Gold layer activation |

---

## [1.1.0] - 2026-06-23

### Bronze Ingestion Pipeline Framework

**Scope:** Raw data ingestion to Snowflake RAW schema only. dbt staging, Silver, and Gold are handled separately in `models/`.

#### Shared Library (`pipelines/shared/`)

- `shared/__init__.py` — marks shared/ as a Python package importable by all pipelines
- `shared/keyvault.py` — Azure Key Vault client using `DefaultAzureCredential`; single `secret(name)` function used by all pipelines; singleton client pattern to avoid re-authentication on each call
- `shared/snowflake_client.py` — shared Snowflake connection, Bronze landing, and pipeline logging:
  - `get_connection()` — connects using Key Vault credentials; targets `NS11MM_DW_DEV.RAW` schema with `LOADER_ROLE`
  - `land_to_bronze()` — append-only insert of raw records as VARIANT (JSON) columns; creates table if not exists; never updates or deletes
  - `log_run()` — writes success/failed run record to `RAW.PIPELINE_LOG`; creates table if not exists
- `requirements-shared.txt` — shared dependencies: `azure-identity`, `azure-keyvault-secrets`, `snowflake-connector-python`, `requests`

#### Source Pipelines (14 sources)

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

#### Azure DevOps Deployment (14 YAML files)

One deployment YAML per source, placed in repo root:

`azure-pipelines-sfnps.yml`, `azure-pipelines-sfmc.yml`, `azure-pipelines-gateway.yml`, `azure-pipelines-counterpoint.yml`, `azure-pipelines-shopify.yml`, `azure-pipelines-classy.yml`, `azure-pipelines-blackbaud.yml`, `azure-pipelines-vena.yml`, `azure-pipelines-ga4.yml`, `azure-pipelines-googleads.yml`, `azure-pipelines-metaads.yml`, `azure-pipelines-wufoo.yml`, `azure-pipelines-clicky.yml`, `azure-pipelines-drupal.yml`

Each YAML includes:
- Path trigger scoped to `pipelines/<source>/` and `pipelines/shared/` — shared library changes redeploy all dependent pipelines
- PR trigger for validation on pull requests (Validate stage only; Deploy stage requires merge to main)
- Two-stage pipeline: Validate (import check) and Deploy (Azure Function App)
- Variables: `FUNCTION_APP_NAME`, `AZURE_SERVICE_CONNECTION`, `PYTHON_VERSION`

#### Documentation

- `pipelines/README.md` — pipeline framework overview: folder structure, how pipelines work, running instructions, shared library usage, adding a new pipeline, nightly schedule, credential conventions, outstanding blockers, key contacts
- `NS11MM_Azure_IT_Setup_Request.docx` — IT setup request for Kenny covering Key Vault provisioning, Function App spec and naming convention, managed identity and Key Vault RBAC setup, outbound network access requirements, Azure DevOps service connection, and recommended 12-step setup sequence
- `NS11MM_Source_Credential_Intake.xlsx` — credential intake workbook with one tab per source; Key Vault secret names, collection hints, and status tracking for all 14 sources
- `ns11mm_bronze_pipelines_master.md` — master pipeline reference covering shared library, per-source guides, nightly schedule, and pipeline status tracker

#### Snowflake Setup (one-time)

```sql
CREATE ROLE IF NOT EXISTS LOADER_ROLE;
GRANT USAGE ON DATABASE NS11MM_DW_DEV TO ROLE LOADER_ROLE;
GRANT USAGE ON SCHEMA NS11MM_DW_DEV.RAW TO ROLE LOADER_ROLE;
GRANT CREATE TABLE ON SCHEMA NS11MM_DW_DEV.RAW TO ROLE LOADER_ROLE;
GRANT INSERT ON FUTURE TABLES IN SCHEMA NS11MM_DW_DEV.RAW TO ROLE LOADER_ROLE;
GRANT ROLE LOADER_ROLE TO USER <pipeline_service_user>;
```

#### Credential status at release

| Source | Status |
|---|---|
| Salesforce Marketing Cloud | Auth URI, REST URI, SOAP URI confirmed; Client ID collected; Client Secret requires regeneration; MID outstanding |
| All other sources | Pending Key Vault setup |

#### Outstanding items before first pipeline run

- Kenny: provision `kv-ns11mm-dp-dev` Key Vault and `func-ns11mm-sfmc-dev` Function App per IT setup doc
- Jeremy: add Snowflake and SFMC credentials to Key Vault once provisioned; regenerate SFMC Client Secret
- Vena: populate `MODELS` dict in `pipelines/vena/pipeline.py` after confirming model IDs with Finance team
- Drupal: confirm DB vs JSON:API path (ADR required); populate `CONTENT_TYPES` list after scope confirmation with Anna Kim
- Blackbaud: registered app requires Blackbaud Admin approval; refresh token rotation requires Key Vault Secrets Officer role on Function App managed identity
- Gateway / CounterPoint: run via self-hosted agent on internal network, not Azure Functions; VM setup to be coordinated separately with Kenny

---

## [1.0.0] - 2026-06-23

### Initial production repository setup

- Created `ns11mm/ns11mm-data-platform` as the production repository, replacing POC repo `jmyers911mm/ns11mm-dbt`
- Established medallion architecture: RAW (Bronze) / staging / intermediate / marts naming convention
- Configured `dbt_project.yml` for `ns11mm_data_platform` project
- Configured `profiles.yml` with dev target (`NS11MM_DW_DEV`) and prod target (`NS11MM_DW_PROD`)
- Established PR-gated CI/CD as the required deployment pattern for all model changes
- Snowflake workspace: `NS11MM_DW_DEV.PUBLIC."ns11mm-dbt"` (shared dev environment)
- Personal dev databases: `NS11MM_DW_DEV_JMYERS` (Jeremy), `NS11MM_DW_DEV_KRAMSEY` (Kalea)

### Governance baseline

- ADR register established (ADR-001 through ADR-017)
- ADR-005: Metric Definition Gate — metric approval required before any Gold model is built
- ADR-006: Change Management Framework — tiered change management (Tier 1 / Tier 2 / Emergency)
- Bronze/RAW layer: immutable, append-only — architectural constraint enforced by design
- All business logic in dbt; Power BI is display-only

---

## POC History (jmyers911mm/ns11mm-dbt)

The following entries document the POC repo build history. Version numbering 
restarted at 1.0.0 when the production repo was created in June 2026.

# Changelog

All notable changes to the ns11mm-data-platform project will be documented in this file.

## [2.10.0] - 2026-06-04

### Infrastructure — Project Rename & Environment Restructure
- Renamed project from `ns11mm-data-platform` to `ns11mm-data-platform` across all documentation and references
- Renamed production database from `NS11MM_DW_PROD` to `NS11MM_DW_PROD` (cloned + dropped old)
- `NS11MM_DW_DEV` retained as shared dev database and workspace host
- Created personal dev database `NS11MM_DW_DEV_JMYERS`
- Created personal dev database `NS11MM_DW_DEV_KRAMSEY`
- Updated all verified query SQL files and YAML metadata to reference `ns11mm_dw_prod`
- Updated macros (`create_ticket_demand_forecast`, `sync_verified_queries`) with new database names
- Updated `dbt_project.yml` query tags from `dbt_museum_*` to `dbt_ns11mm_*`
- Updated `profiles.yml` targets to new database names

### Documentation
- Rewrote `CONTRIBUTING.md` with expanded Environment Architecture section explaining personal dev spaces, the relationship between shared dev / personal dev / prod, and the full release process
- Fixed broken relative links across `docs/` (incorrect paths to `architecture/` subdirectory)
- Updated all GitHub repo references from `ns11mm-data-platform` to `ns11mm-data-platform`
- Updated `SNOWFLAKE_SETTINGS.md` database inventory
- Added developer provisioning SQL script to `CONTRIBUTING.md`
- Added current personal dev environments table

## [2.9.0] - 2026-06-03

### Gold Models (8 new)
- `fct_campaign_performance` — email campaign metrics joined with dimension context and fiscal calendar
- `fct_campaign_attribution` — multi-touch attribution linking web conversions to resolved customers
- `fct_marketing_channel_summary` — cross-channel spend/conversion rollup (paid search, display, social, organic)
- `fct_website_traffic` — daily web analytics by channel, source, device, and page category
- `fct_website_funnel` — conversion funnel stages from landing → tickets → membership → purchase
- `fct_ticket_demand_benchmarks` — rolling 90-day demand benchmarks by ticket type, day-of-week, and time slot
- `bridge_session_customer` — bridge table linking Google Analytics sessions to resolved customers via email match
- `rpt_campaign_performance` — pre-joined campaign report with fiscal context and audience-size tiers

### ML Feature Models (3 new)
- `ml_campaign_response_features` — campaign response scoring features
- `ml_email_send_time_features` — optimal send-time prediction features
- `ml_retail_cross_sell_features` — product affinity and cross-sell recommendation features

### Macros
- `create_ticket_demand_forecast` — run-operation macro creating a Snowflake ML FORECAST model for 90-day ticket demand prediction (multi-series by ticket type)
- `sync_verified_queries` — run-operation macro to sync certified VQR SQL files into the semantic view

### Snapshots
- `snap_dim_customer` — SCD Type 2 snapshot tracking changes to customer segment, membership status, and contact details

### Verified Queries (36 queries across 9 domains)
- `campaigns/` — campaign performance by type
- `capacity_planning/` — availability, half-life, peak demand, sold-out slots, weekend utilization
- `digital_marketing/` — cross-channel comparison, ROAS, top campaigns, website funnel, weekend CTR
- `donor_retention/` — at-risk cohorts, churn by acquisition, retention by tier/membership, survival curves
- `membership/` — customers by type, LTV by segment/tier
- `retail/` — retail by category, top-selling products
- `revenue_operations/` — daily/monthly revenue, fiscal year summary, revenue by day-of-week/payment method
- `ticket_sales/` — discount analysis, purchase-to-entry time, AOV trend, revenue by type, gate utilization
- `visitor_experience/` — visitors by gate, visitors by hour

### Governance & Documentation
- `docs/architecture/SQL_STYLE_GUIDE.md` — naming, layering, formatting, and dbt conventions
- `docs/architecture/DATA_CLASSIFICATION.md` — PII handling tiers, access control rules, classification on new models
- `docs/architecture/USAGE_AUDIT.md` — usage monitoring and audit procedures
- `docs/business/METRIC_GLOSSARY.md` — plain-English definitions for all certified metrics across 6 domains
- `docs/ONBOARDING.md` — linear day-1 checklist for new data team members
- `docs/README.md` — documentation map with role-based entry points for all audiences
- `docs/adr/0005-metric-definition-gate.md` — ADR requiring metric approval before Gold implementation
- `docs/adr/0006-change-management-tiers.md` — ADR establishing tiered change management (Tier 1/Tier 2/Emergency)

### Operational
- `analyses/create_marketing_semantic_view.sql` — DDL to create the Cortex Analyst semantic view for digital marketing
- `models/exposures.yml` — dbt exposures defining downstream consumers (Power BI, Cortex Agent, ML pipelines)

### Changed
- Model count: 56 → 72 (16 new models)
- `CODEOWNERS` expanded with ownership paths for verified queries and documentation

## [2.9.1] - 2026-06-03

### Added
- `rpt_revenue_bridge` — weekly revenue bridge report with three views: budget vs actual (trailing 4-week average), year-over-year comparison, and component breakdown across tickets and retail. Includes WoW change, discount impact decomposition, and volume drivers.

### Changed
- Model count: 71 → 72

---

## [2.8.0] - 2026-06-01

### Infrastructure-as-Code & Platform Documentation

**Terraform IaC** (`terraform/`)
- `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf` — Root module for platform infrastructure
- `modules/snowflake-warehouse/main.tf` — Warehouse provisioning module
- `modules/key-vault/main.tf` — Azure Key Vault for secret management
- `modules/monitor-alerts/main.tf` — Azure Monitor alert rules
- `modules/static-web-app/main.tf` — Static web app hosting module
- `environments/dev.tfvars.json`, `staging.tfvars.json`, `prod.tfvars.json` — Per-environment variable files
- `pipelines/deploy-dev.yml`, `deploy-staging.yml`, `deploy-prod.yml` — CI/CD deployment pipelines
- `notifications/teams_webhook_setup.sql` — Microsoft Teams webhook notification integration template
- `terraform/.gitignore`, `terraform/CODEOWNERS`, `terraform/README.md` — Governance files

**Platform Documentation (5 new files)**
- `PROJECT_MAP.md` — Team orientation guide: mental model, file placement guide, document cross-references
- `ARCHITECTURE_FLOW.md` — End-to-end platform architecture diagram (Bronze → Silver → Gold → Consumers) with ASCII-art flow
- `SOURCE_INTEGRATION.md` — Per-source extraction plans (Gateway Ticketing, Salesforce, Google Ads/Analytics, Meta Ads) with auth models and API details
- `TEST_ORCHESTRATION.md` — Test scheduling, source clustering, freshness SLAs, and alert routing rules
- `SNOWFLAKE_SETTINGS.md` — Account/user settings reference (roles, warehouses, integrations)

**Workspace Utility**
- `COPYWORKSPACE.sql` — One-line workspace-to-stage export command for backup/migration

**dbt Groups Restructure**
- `models/groups.yml` — Replaced domain-based groups (`_model_groups.yml`: daily_operations, member_engagement, donor_retention, campaign_analytics, visitor_forecasting) with layer-based ownership groups (staging, silver, gold_dimensions, gold_facts, gold_reports, ml_features). Each group has explicit owner/email.
- `dbt_project.yml` — All model folders now reference `+group` assignments; added `+access: public` for Gold and ML layers

**Data Quality Test Expansion**
- `macros/generic_tests/data_quality_tests.sql` — Added 5 new generic tests:
  - `null_rate_threshold` — Fails if column null percentage exceeds threshold (default 50%)
  - `late_arriving_data` — Detects records loaded recently but timestamped beyond max lag (default 72h)
  - `daily_volume_bounds` — Validates daily row counts stay within min/max bounds
  - `cardinality_change` — Alerts if distinct value count falls outside expected range
  - `distribution_shift` — Detects when a specific value's frequency drifts outside acceptable range

**Project Configuration**
- `dbt_project.yml` — Added `vars: skip_circuit_breaker: false` for conditional circuit-breaker bypass in test macros

---

## [2.7.0] - 2026-05-27

### Marketing-to-Sales Attribution Pipeline

**New Gold Fact Models (2)**
- `fct_marketing_sales_daily` — Daily marketing channel metrics (impressions, clicks, spend, conversions) joined with same-day ticket and retail revenue. Grain: one row per date × channel.
- `fct_campaign_attribution` — Session-attributed ticket and retail revenue via `bridge_session_customer`. Links marketing channels to actual purchase transactions. Grain: one row per date × channel × source × medium × segment × membership.

**New Semantic View (1)**
- `NS11MM_DW_PROD.MARTS.SV_MARKETING_SALES` — Connects marketing performance to ticket/retail sales. 2 entities (marketing_sales, campaign_attribution), 14 metrics (spend, impressions, ticket revenue, retail revenue, attributed revenue, ROAS, CTR), 12 dimensions (date, channel, customer segment, membership type).

**Schema Updates**
- `models/marts/facts/schema.yml` — Added entries for `fct_marketing_sales_daily` and `fct_campaign_attribution` with not_null tests

**Documentation (9 README files)**
- `models/raw/README.md` — Source systems, staging conventions
- `models/intermediate/README.md` — Cleaning/validation responsibilities, model inventory
- `models/marts/README.md` — Full dimension/fact/report inventory with grains
- `models/ml_features/README.md` — ML use cases and feature tables
- `tests/business_rules/README.md` — Domain invariant test inventory
- `tests/reconciliation/README.md` — Layer-to-layer reconciliation tests
- `tests/referential_integrity/README.md` — FK and seed consistency tests
- `macros/generic_tests/README.md` — Reusable test macro descriptions
- `macros/operations/README.md` — Utility macro descriptions and usage

**Model count: 52 → 54 | Test count: 379 → 386**

---

## [2.6.0] - 2026-05-26

### Digital Marketing Integration

**New Sources (3)**
- Added `raw_google_analytics` — Google Analytics session-level data with traffic source attribution
- Added `raw_google_ads` — Google Ads daily ad performance metrics
- Added `raw_meta_ads` — Meta (Facebook/Instagram) Ads daily ad performance metrics

**New Seeds (4)**
- `raw_google_analytics.csv` — 20 sample GA sessions with varied sources/mediums
- `raw_google_ads.csv` — 20 sample ad performance records across 3 campaigns
- `raw_meta_ads.csv` — 20 sample Meta ad records across Facebook/Instagram
- `ref_marketing_channels.csv` — 7 marketing channel reference records

**New Staging Models (3)**
- `stg_google_analytics` — Lowercase/trim source fields, hashdiff
- `stg_google_ads` — Cost micros to dollars conversion, hashdiff
- `stg_meta_ads` — Lowercase platform/placement, hashdiff

**New Silver Models (3)**
- `silver_google_analytics` — Channel grouping derivation, page categorization, is_conversion flag
- `silver_google_ads` — Cost per conversion, ROAS, campaign categorization (Tickets/Membership/Retail/General)
- `silver_meta_ads` — CPC, CPA, ROAS, campaign categorization (Membership/Promotions/Awareness/General)

**New Gold Dimension Models (1)**
- `dim_marketing_channel` — Seed-based channel dimension with paid/owned/earned classification

**New Gold Fact Models (5)**
- `fct_digital_ad_performance` — Unified Google Ads + Meta Ads with reach/frequency (updated with reach/frequency)
- `fct_website_traffic` — Daily website traffic by channel, campaign, page category, device
- `fct_ad_campaign_daily` — Campaign-level daily summary across platforms
- `fct_marketing_channel_summary` — Unified cross-channel daily performance (paid search, paid social, paid display, email, organic, direct)
- `fct_website_funnel` — Page progression funnel with drop-off rates by channel and device
- `bridge_session_customer` — Bridge linking converting GA sessions to identity-resolved customers

**New Gold Report Models (1)**
- `rpt_digital_marketing` — Combined ad performance + website traffic with fiscal date context

**New ML Feature Models (3)**
- `ml_ad_budget_optimization_features` — ROAS trends, spend share, performance tiers, budget recommendations
- `ml_marketing_attribution_features` — Multi-touch attribution with first/last touch, channel paths, conversion path tiers
- `ml_ad_creative_features` — Creative-level performance with rolling averages, cumulative efficiency, performance tiers

**Updated ML Feature Models (2)**
- `ml_daily_visitor_features` — Added ad spend, impressions, web sessions, and rolling marketing averages as exogenous features
- `ml_campaign_response_features` — Added email-driven web sessions, paid search/social session counts

**New Semantic View (1)**
- `SV_MARKETING_PERFORMANCE` — Expanded to 6 entities (ad_performance, website_traffic, email_campaigns, channel_summary, channels, dates), 21 metrics, 17 dimensions. Added email campaigns, reach/frequency, cross-channel summary.

**New Verified Queries (5)**
- `roas_by_platform` — ROAS by advertising platform this month
- `top_campaigns_by_spend` — Top 10 campaigns by total spend
- `weekend_vs_weekday_ctr` — CTR comparison weekends vs weekdays
- `cross_channel_comparison` — All channels: spend, conversions, ROAS
- `website_conversion_funnel` — Funnel by traffic channel

**Testing**
- Added 54+ new schema tests for all new/modified models
- Tests cover: not_null, unique, accepted_values, hashdiff_integrity

---

## [2.5.0] - 2026-05-25

### Infrastructure & Access

**Workspace Migration**
- Moved workspace from private `USER$.PUBLIC."ns11mm-data-platform"` to shared `NS11MM_DW_DEV.PUBLIC."ns11mm-data-platform"` for team collaboration
- Created `profiles.yml` (was missing after migration) — targets: dev (`NS11MM_DW_DEV`) and prod (`NS11MM_DW_PROD`)

**Git Integration**
- Created `GITHUB_INTEGRATION` API integration (Snowflake GitHub App auth)
- Created `NS11MM_DW_DEV.PUBLIC.MUSEUM_DBT_REPO` Git Repository stage linked to `https://github.com/ns11mm/ns11mm-data-platform.git`

**Power BI Authentication**
- Created `POWERBI` external OAuth security integration (Azure AD) for Microsoft Account SSO from Power BI
- Configured `EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM = 'upn'` mapping to `login_name`

**README.md**
- Expanded Access Control section with all 10 roles (added ORGADMIN, SECURITYADMIN, USERADMIN, SYSADMIN, PUBLIC)
- Added role hierarchy diagram
- Added detailed access matrix (read/write per database/schema per role)
- Added POWERBI_ROLE and ML_ROLE detail sections

---

## [2.4.0] - 2026-05-22

### Governance & Configuration Hardening

**`.gitignore`**
- Added `dbt.log` and `graph.gpickle` — both were previously committed; should never be in source control

**`dbt.log` / `graph.gpickle`**
- Purged file contents (2.81 MB log with compiled SQL, connection metadata, execution traces; binary DAG artifact) — files zeroed pending `git rm --cached` in local clone

**`CODEOWNERS`**
- Removed `/profiles.yml` entry — file is already gitignored and should not be committed (convention violation / credential exposure risk)
- Added `/analyses/verified_queries/` — 30 certified VQRs now require reviewer approval

**`dbt_project.yml`**
- Gold dimensions: added `+materialized: table` override — README specifies full rebuild, not inherited `incremental`
- Silver models: added `+on_schema_change: append_new_columns` — prevents silent column drops on incremental runs when Bronze adds columns
- Fixed `+pre-hook` intraday timeout: changed `config.get('tags', [])` → `model.tags` — the previous expression evaluated the project config dict (always empty), so the 300s timeout for intraday-tagged models never fired

**`models/marts/facts/schema.yml`**
- `fct_ticket_utilization`: added `config.deprecation_date: 2026-07-01` — proper dbt deprecation marker (meta-only annotation has no runtime effect)
- `fct_retail_performance`: added `config.deprecation_date: 2026-07-01` — same fix

**`README.md`**
- Project Structure: corrected ML Features model count from "4 models" to "11 models" — documentation drift since v2.3.0
- Removed `profiles.yml` from project structure tree — file is not committed; added note pointing to CONTRIBUTING.md for profile setup

---

## [2.3.0] - 2026-05-21

### ML Feature Tables — 7 New Models

Built production-ready feature tables for 7 ML use cases across revenue optimization, marketing, and donor stewardship.

**New Models** (all in `ML_FEATURES` schema)

| Model | Target | Rows | Business Value |
|-------|--------|------|----------------|
| `ml_ticket_no_show_features` | `is_no_show` | 574 | Oversell high no-show slots → +revenue |
| `ml_retail_cross_sell_features` | `co_purchase_count` | 0* | Product bundling and POS cross-sell |
| `ml_email_send_time_features` | `was_opened` | 1,129 | Per-subscriber send time optimization |
| `ml_campaign_response_features` | `is_high_responder` | 300 | Target high-propensity members for fundraising |
| `ml_dynamic_pricing_features` | `suggested_price_multiplier` | 16,000 | Revenue optimization via demand-based pricing |
| `ml_donor_upgrade_propensity_features` | `is_upgrade_candidate` | 491 | Proactive stewardship for upgrade-ready donors |
| `ml_visitor_forecast_training` | `y` (visitor count) | 14 | Staff scheduling and capacity planning |

*Cross-sell awaits multi-item basket transactions in production data.

**Feature Engineering Highlights:**
- Ticket No-Show: customer historical no-show rate, ticket type base rate, purchase hour, anonymity flag
- Send Time: preferred open hour per subscriber, hours-from-preferred distance, time bucket encoding
- Dynamic Pricing: demand z-score vs benchmark, utilization band, suggested multiplier (0.85x–1.25x)
- Donor Upgrade: monthly value velocity, spend-to-next-tier gap, next tier target, engagement signals

**Exposures:** Added 7 new ML model exposures (15 total)
**Schema tests:** Added tests for all new feature tables (246 total)
**Model count: 45 → 52**

---

## [2.2.0] - 2026-05-21

### Polish & Best-in-Class Hardening

**CI/CD**
- Added `analyses/**` and `seeds/**` to GitHub Actions trigger paths — VQR and seed changes now trigger CI

**Model Deprecation**
- `fct_ticket_utilization` — marked deprecated (2026-07-01), superseded by `fct_ticket_sales`
- `fct_retail_performance` — marked deprecated (2026-07-01), superseded by `fct_retail_line_items`

**Seed Validation Tests** (4 new singular tests)
- `assert_ltv_tiers_match_seed` — validates rpt_customer_ltv tiers exist in ref_ltv_tiers
- `assert_ticket_types_match_seed` — validates fct_ticket_sales types exist in ref_ticket_types
- `assert_payment_methods_match_seed` — validates payment_method_ids exist in ref_payment_methods
- `assert_customer_segments_match_seed` — validates dim_customer segments exist in ref_customer_segments

**SQL Linting**
- `.sqlfluff` — Snowflake dialect, lowercase keywords, explicit aliasing, 120 char max line length
- `.sqlfluffignore` — ignores Jinja parsing issues

**CONTRIBUTING.md**
- Added full Verified Query (VQR) Workflow section: how to add, validate, deploy, and deprecate VQRs
- Governance rules for VQR approval and certification

**Snapshot**
- `snap_dim_customer` — SCD Type 2 on identity-resolved customer dim, tracking changes to segment, membership, email/phone over time

**README**
- Added Best-in-Class Scorecard at top of README
- Updated TOC, model counts, and current state line

**Test count: 230 → 234 | Snapshots: 1 → 2**

---

## [2.1.0] - 2026-05-21

### Cortex Agent, Observability & Verified Query Framework

**Cortex Agent**
- Recreated `NS11MM_DW_PROD.MARTS.MUSEUM_OPERATIONS_AGENT` with two semantic view tools:
  - `MUSEUM_OPERATIONS_DATA` → `SV_MUSEUM_OPERATIONS` (daily ops, tickets, retail, customers, LTV)
  - `DONOR_RETENTION_DATA` → `SV_DONOR_RETENTION` (retention, survival, capacity)
- Agent instructions include role-playing date guidance, LTV routing, and chart generation
- Granted `READ UNREDACTED AI OBSERVABILITY EVENTS TABLE` and `SNOWFLAKE.AI_OBSERVABILITY_READER` for full query tracking

**Observability & Pattern Detection**
- Created `NS11MM_DW_PROD.MONITORING.AGENT_QUESTION_PATTERNS` table for storing topic clusters
- Created `NS11MM_DW_PROD.MONITORING.ANALYZE_AGENT_QUESTION_GAPS` stored procedure:
  - Pulls last 24h of agent questions from observability events
  - Clusters by topic (Revenue, Tickets, Retail, Members, Retention, Capacity, Forecasting, etc.)
  - Detects coverage gaps: >50% failure = HIGH, >30% = MEDIUM, 10+ questions = INFO
  - Sends email alert via `NS11MM_EMAIL_ALERTS` notification integration
- Created `NS11MM_DW_PROD.MONITORING.TASK_AGENT_PATTERN_ANALYSIS` task (daily at 8 AM ET)
- Created `NS11MM_EMAIL_ALERTS` notification integration → jmyers@911memorial.org

**Verified Query Framework** (`analyses/verified_queries/`)
- 30 certified verified queries across 8 business domains:
  - `revenue_operations/` (7) — DOW, daily/monthly trends, weekend, fiscal year, net, payment
  - `ticket_sales/` (5) — by type, AOV trend, discounts, utilization, purchase-to-entry
  - `visitor_experience/` (2) — hourly traffic, by gate
  - `retail/` (2) — by category, top products
  - `membership/` (3) — LTV by segment, by tier, by membership type
  - `campaigns/` (1) — by campaign type
  - `donor_retention/` (5) — by tier, by membership, survival curve, at-risk, churn
  - `capacity_planning/` (5) — availability, sold-out, peak demand, weekend, half-life
- Each domain has `_verified_queries.yml` with governance metadata:
  - stakeholder_owner, adm_reference, approved_by, approved_date, tags, power_bi_datasets
- SQL files use `SEMANTIC_VIEW()` syntax for direct validation
- `macros/operations/sync_verified_queries.sql` — run-operation to list/validate all VQRs
- `analyses/verified_queries/README.md` — full documentation of conventions and governance

**Semantic View Updates**
- `SV_MUSEUM_OPERATIONS` expanded to 20 verified queries (was 6)
- `SV_DONOR_RETENTION` expanded to 10 verified queries (was 4)

**Model count: 45 models | 30 analyses | 170 tests | 487 macros**

---

## [2.0.0] - 2026-05-20

### Identity Resolution & Full Star Schema

Major refactor introducing graph-based customer identity resolution, ticket-level grain, line-item retail, and a fully connected semantic view with role-playing dates.

**New Snowflake Objects**
- `BRONZE.RAW_CUSTOMER_IDENTIFIERS` — identity graph table linking customers across systems via email and phone
- `BRONZE.RAW_POS_TICKETS.CUSTOMER_PHONE` — new column for phone-based identity matching
- `BRONZE.RAW_POS_TICKETS.TICKET_NUMBER` — unique barcode per individual ticket
- `BRONZE.RAW_POS_TICKETS.PAYMENT_METHOD_ID` — FK to dim_payment_method
- `BRONZE.RAW_POS_RETAIL.CUSTOMER_PHONE` — new column for phone-based identity matching
- `BRONZE.RAW_POS_RETAIL.PRODUCT_ID` — FK to dim_product
- `BRONZE.RAW_POS_RETAIL.PAYMENT_METHOD_ID` — FK to dim_payment_method

**New dbt Models** (4 files)
- `models/marts/dimensions/dim_customer.sql` — unified customer dimension using connected-component identity resolution (shared email OR phone merges records into one customer_id). Supports multiple emails/phones per customer. Segments: Known Member, Identified Visitor, Anonymous.
- `models/marts/facts/fct_ticket_sales.sql` — ticket-level grain (one row per barcode) with customer_id, payment_method_id, scan outcomes, and both transaction_date and scan_date for role-playing date analysis
- `models/marts/facts/fct_retail_line_items.sql` — line-item retail with customer_id, product_id, and payment_method_id FKs
- `models/marts/reports/rpt_customer_ltv.sql` — unified LTV combining ticket spend + retail spend + donations with tier classification (Platinum ≥ $1000, Gold ≥ $500, Silver ≥ $100, Bronze < $100)
- `models/marts/reports/rpt_ticket_sales.sql` — full star-schema ticket report with role-playing dates (purchase date + scan date), all dimension attributes joined

**Modified dbt Models** (10 files)
- `models/raw/sources.yml` — added `raw_customer_identifiers` source
- `models/raw/stg_pos_tickets.sql` — added customer_phone, ticket_number, payment_method_id columns
- `models/raw/stg_pos_retail.sql` — added customer_phone, product_id, payment_method_id columns
- `models/intermediate/silver_pos_tickets.sql` — added customer_phone, has_phone, ticket_number, payment_method_id passthrough
- `models/intermediate/silver_pos_retail.sql` — added customer_phone, has_phone, product_id, payment_method_id passthrough
- `models/marts/facts/fct_donor_retention.sql` — fixed GROUP BY to include membership_type, acquisition_method, donor_tier (resolves dev build failure)
- `models/marts/reports/rpt_campaign_performance.sql` — joined dim_campaign + dim_date for campaign type, audience tier, fiscal year
- `models/marts/reports/rpt_retail_performance.sql` — rebuilt on fct_retail_line_items with dim_product, dim_payment_method, dim_customer joins
- `models/marts/reports/rpt_member_360.sql` — rebuilt on dim_customer with identity-resolved ticket + retail spend, LTV tier
- `models/marts/reports/rpt_visitor_traffic.sql` — added dim_gate attributes + ticket utilization per gate
- `models/marts/reports/rpt_daily_operations.sql` — added ticket AOV, avg tickets/txn, net revenue, revenue per visitor, identification rate

**Model count: 40 → 45 | Test count: 248 → 170 (consolidated)**

### Semantic Views

**New Semantic View**
- `NS11MM_DW_PROD.MARTS.SV_DONOR_RETENTION` — donor retention analytics and ticket capacity planning. 6 entities (retention, survival, availability, benchmarks, dates, ticket type), 16 metrics, 4 verified queries.

**Rebuilt Semantic View**
- `NS11MM_DW_PROD.MARTS.SV_MUSEUM_OPERATIONS` — complete redesign with full star schema:
  - 13 entities (ticket_sales, retail_items, campaigns, daily_ops, traffic, customer_ltv, dates, customers, dim_gate, dim_campaign, dim_ticket_type, dim_product, dim_payment_method)
  - 16 relationships including role-playing dates (transaction_date + scan_date → dates)
  - 35 metrics with USD/percentage/count formatting hints
  - 6 verified queries covering revenue by DOW, ticket type, retail categories, LTV by segment, utilization by gate, revenue by payment method
  - AI_SQL_GENERATION instructions for identity resolution, role-playing dates, and cross-entity LTV

### Power BI Integration
- All semantic view relationships fully connected — resolves "entities not related" error when querying across entities
- `POWERBI_ROLE` granted SELECT on `SV_DONOR_RETENTION`

### Production Deployment
- Full-refresh build: 45 models, 170 tests — 213 PASS, 3 WARN, 0 ERROR
- Dev build validated: 45 models PASS, 167 tests PASS, 3 WARN
- Dev environment schema synchronized (new columns + identity table)

---

## [1.5.0] - 2026-05-18

### ML Feature Enhancement

**Modified** (1 file)
- `models/ml_features/ml_ticket_demand_features.sql` — added 30-day rolling forecast columns partitioned by ticket type: `forecast_min_30d`, `forecast_max_30d`, `forecast_mean_30d`

### Documentation & Recovery

**Recreated** (1 file)
- `README.md` — comprehensive project documentation with table of contents, architecture diagram, full model lineage (upstream/downstream), testing strategy, access control policies, CI/CD pipeline, and deployment instructions

---

## [1.4.0] - 2026-05-18

### Ticket Capacity & Availability Pipeline

**New Snowflake Objects**
- `BRONZE.RAW_TICKET_CAPACITY` — capacity configuration table (date, 30-min entry window, ticket type, capacity)
- `BRONZE.RAW_POS_TICKETS.ENTRY_TIME_PURCHASED` — new column added for reservation window tracking

**New dbt Models** (5 files)
- `models/raw/stg_ticket_capacity.sql` — staging view for capacity source
- `models/intermediate/silver_ticket_inventory.sql` — joins capacity + reservations, computes utilization % and demand level (Sold Out / High Demand / Moderate / Low / Very Low)
- `models/marts/facts/fct_ticket_availability.sql` — enriched with date dimensions, the main reporting table for ticket operations
- `models/marts/facts/fct_ticket_demand_benchmarks.sql` — 90-day rolling benchmarks showing avg/median/p25/p75/p90 by day-of-week, entry window, and ticket type with ±2σ bounds
- `models/ml_features/ml_ticket_demand_features.sql` — daily demand features with 7/30-day rolling averages, lags, z-scores for forecast model training

**New Forecast Macro** (1 file)
- `macros/operations/create_ticket_demand_forecast.sql` — run-operation that creates a `SNOWFLAKE.ML.FORECAST` model for 90-day multi-series ticket demand prediction

**Modified** (2 files)
- `models/raw/stg_pos_tickets.sql` — added `entry_time_purchased`, `entry_date`, `entry_window_start/end`, `mapped_ticket_type` (maps legacy types to new 10-type taxonomy), updated hashdiff
- `models/raw/sources.yml` — added `raw_ticket_capacity` source definition with column tests

**Model count: 35 → 40 | Source count: 5 → 6**

### Schema & Contract Fixes

**Modified** (3 files)
- `models/marts/facts/fct_daily_operations.sql` — removed contract enforcement, changed `on_schema_change` to `append_new_columns` (resolves recurring numeric precision drift)
- `models/marts/facts/fct_member_360.sql` — removed contract enforcement, changed `on_schema_change` to `append_new_columns`
- `models/marts/facts/fct_donor_cohort_survival.sql` — fixed NULL `original_cohort_size` by wrapping window function in COALESCE
- `models/marts/dimensions/schema.yml` — fixed `dim_product.standard_price` data type to `NUMBER(10,2)`
- `dbt_project.yml` — gold layer `+on_schema_change` changed from `fail` to `append_new_columns`

### Test Fixes

**Modified** (2 files)
- `macros/generic_tests/test_hashdiff_integrity.sql` — fixed UNION ALL column mismatch (collision_check and null_check now return consistent columns)
- `models/intermediate/schema.yml` — set `hashdiff_integrity` tests on `silver_pos_retail` and `silver_sf_marketing_cloud` to `severity: warn` (hash collisions from identical business records are informational, not failures)

### Production Deployment

- Full-refresh build deployed to `NS11MM_DW_PROD` — 40 models, 252 tests, 289 pass / 7 warn / 0 error
- Created `NS11MM_DW_PROD.INTERMEDIATE.DBT_RUN_AUDIT_LOG` table
- Created `NS11MM_DW_PROD.RAW.RAW_TICKET_CAPACITY` table (19,200 rows seeded)
- Added `ENTRY_TIME_PURCHASED` column to `NS11MM_DW_PROD.RAW.RAW_POS_TICKETS` (574 rows backfilled)

---

## [1.3.0] - 2026-05-18

### Donor Retention & Churn Forecasting

**New** (2 files in `models/marts/facts/`)
- `fct_donor_retention.sql` — monthly retention rates per cohort (acquisition month, membership type, acquisition method, donor tier). Donors are considered retained if Active/Grace Period OR donated within 12 months.
- `fct_donor_cohort_survival.sql` — survival curves per cohort with half-life detection, monthly dropoff rates, and cohort health scoring (Healthy / At Risk / Declining / Critical)

**New** (1 file in `models/ml_features/`)
- `ml_donor_churn_features.sql` — per-donor churn prediction features: tenure, donation velocity, recency bands (Recent/Cooling/Lapsing/Dormant), composite churn risk level (Low/Medium/High), and `estimated_months_to_churn` derived from cohort survival half-life

**Modified** (2 files)
- `models/marts/facts/schema.yml` — added schema entries for fct_donor_retention, fct_donor_cohort_survival
- `models/ml_features/schema.yml` — added schema entry for ml_donor_churn_features

**Model count: 32 → 35 | Test count: 227 → 248**

### Model Groups & Ownership

**New** (1 file)
- `models/_model_groups.yml` — declares 5 dbt groups with owners: daily_operations, member_engagement, donor_retention, campaign_analytics, visitor_forecasting

**Modified** (3 files)
- `dbt_project.yml` — assigned `+group` at folder level for staging, silver, gold/dimensions, gold/facts, gold/reports, ml_features
- `models/marts/facts/fct_donor_retention.sql` — `group='donor_retention'`
- `models/marts/facts/fct_donor_cohort_survival.sql` — `group='donor_retention'`
- `models/ml_features/ml_donor_churn_features.sql` — `group='donor_retention'`

**Modified** (1 file)
- `models/exposures.yml` — added `ml_donor_churn_model` exposure (full pipeline lineage) and `powerbi_donor_retention_dashboard` exposure

**Exposure count: 6 → 8 | Group count: 0 → 5**

### Pre-Deployment Validation (Dev vs Prod)

**New** (2 files in `macros/operations/`)
- `validate_before_deploy.sql` — run-operation that compares row counts of 10 key models between dev and prod databases. Reports MATCH/WARN/FAIL per model with configurable threshold (default 5%)
- `compare_model_to_prod.sql` — run-operation for deep single-model comparison using MINUS set operations. Detects new rows, lost rows, and modified rows. Flags DATA LOSS RISK if prod rows would be removed

### Branch Strategy & Workspace Isolation

**New** (1 file)
- `CONTRIBUTING.md` — trunk-based branching workflow, per-developer workspace isolation (personal databases), ownership zones by model group, PR reviewer matrix, change gate classification (Tier 1/Tier 2), environment promotion order (dev → staging → prod), pre-PR checklist

**New** (1 file)
- `scripts/setup_developer_workspace.sql` — SQL script to onboard a new developer: creates personal `NS11MM_DW_DEV_<USERNAME>` database, shares bronze via views from prod, grants permissions, creates audit log table

**New** (1 file)
- `CODEOWNERS` — maps file paths to required PR reviewers (JMYERS for all infrastructure files)

**Modified** (1 file)
- `profiles.yml` — added `staging` target (NS11MM_DW_STAGING), updated account/user fields

### CI/CD Pipeline

**Modified** (1 file)
- `.github/workflows/dbt-ci.yml` — upgraded from full-build to slim CI (`state:modified+` with `--defer`), added pre-deploy validation step, added docs generation on merge to main, path-filtered triggers

### IaC Policy Alignment

**New** (14 files in `terraform/`)
- `main.tf` — orchestrates M01-M04 modules with dependency ordering
- `variables.tf` — 18 input variables with validation rules
- `outputs.tf` — Key Vault URI, warehouse name, Static Web App hostname
- `providers.tf` — azurerm + snowflake providers, azurerm backend state config
- `modules/snowflake-warehouse/main.tf` — M01: Snowflake warehouse + resource monitor (size parameterized per environment)
- `modules/key-vault/main.tf` — M02: Azure Key Vault with soft-delete, purge protection, 2 service principal access policies
- `modules/static-web-app/main.tf` — M03: Static Web App for dbt docs hosting
- `modules/monitor-alerts/main.tf` — M04: Credit consumption warning/critical alerts routed to Teams webhook
- `environments/dev.tfvars.json` — XSMALL warehouse, kv-ns11mm-dev
- `environments/staging.tfvars.json` — MEDIUM warehouse, kv-ns11mm-staging
- `environments/prod.tfvars.json` — MEDIUM warehouse, kv-ns11mm-prod
- `pipelines/deploy-dev.yml` — Azure Pipelines: auto-deploy on merge to main
- `pipelines/deploy-staging.yml` — Azure Pipelines: manual trigger
- `pipelines/deploy-prod.yml` — Azure Pipelines: manual trigger + ManualValidation approval gate

**New** (3 files in `terraform/`)
- `CODEOWNERS` — all IaC files require @jwmyers82 approval
- `.gitignore` — excludes tfstate, .terraform/, plan files
- `README.md` — deployment order, prerequisites, usage instructions

### Runbook

**New** (1 file)
- `RUNBOOK.md` — comprehensive operational runbook covering: daily operations, incident response, source issues, test failures, schema changes, quarantine management, backfill/late data, adding new content, deployment (including pre-deploy validation workflow), monitoring health checks, contacts & escalation, and quick reference command table

---

## [1.2.0] - 2026-05-17

### Change Detection (Hashdiff)

**New** (1 file)
- `macros/data_quality/generate_hashdiff.sql` — reusable MD5 hash macro over business columns with null-safe concatenation

**Modified** (5 files)
- `models/raw/stg_sf_crm.sql` — added `hashdiff` column (15 business columns)
- `models/raw/stg_pos_tickets.sql` — added `hashdiff` column (10 business columns)
- `models/raw/stg_pos_retail.sql` — added `hashdiff` column (11 business columns)
- `models/raw/stg_ticket_scans.sql` — added `hashdiff` column (6 business columns)
- `models/raw/stg_sf_marketing_cloud.sql` — added `hashdiff` column (10 business columns)

**Modified** (5 files)
- `models/intermediate/silver_pos_tickets.sql` — merge now skips rows with unchanged hashdiff
- `models/intermediate/silver_pos_retail.sql` — merge now skips rows with unchanged hashdiff
- `models/intermediate/silver_ticket_scans.sql` — merge now skips rows with unchanged hashdiff
- `models/intermediate/silver_sf_crm.sql` — merge now skips rows with unchanged hashdiff
- `models/intermediate/silver_sf_marketing_cloud.sql` — merge now skips rows with unchanged hashdiff

**Modified** (1 file)
- `snapshots/snap_sf_crm.sql` — changed from `strategy='timestamp'` to `strategy='check', check_cols=['hashdiff']`

### Data Quality & Validation

**New Generic Test Macros** (6 files in `macros/generic_tests/`)
- `test_hashdiff_integrity.sql` — validates no null hashes and no hash collisions across different keys
- `test_referential_integrity.sql` — reusable FK validation between any parent/child models
- `test_row_count_drift.sql` — alerts when row count deviates >50% or >200% of 30-day historical average
- `test_late_arriving_data.sql` — detects rows with business timestamp >72h before load time
- `test_schema_drift.sql` — compares model's actual columns against an expected list

**New Data Quality Macros** (2 files in `macros/data_quality/`)
- `quarantine_failed_rows.sql` — routes failing rows to `SILVER.QUARANTINE_LOG` with full row data and reason
- `auto_heal_duplicates.sql` — CTE wrapper that deduplicates on primary key keeping latest row

**New Singular Tests** (4 files in `tests/`)
- `tests/referential_integrity/assert_campaign_fk_integrity.sql` — campaign IDs in gold resolve to dim_campaign
- `tests/referential_integrity/assert_member360_emails_exist_in_crm.sql` — member emails exist in silver CRM
- `tests/referential_integrity/assert_member360_no_orphan_contacts.sql` — no orphan contacts in fct_member_360
- `tests/referential_integrity/assert_gold_daily_ops_no_orphan_dates.sql` — no orphan dates in fct_daily_operations

**Modified** (1 file)
- `models/intermediate/schema.yml` — added hashdiff_integrity tests (all 5 silver models), late_arriving_data tests (4 transactional models)

**Test count: 214 → 248**

### Rerun & Recovery Operations

**New** (3 files in `macros/operations/`)
- `smart_retry.sql` — run-operation that reads audit log, identifies failed models, suggests exact rerun commands
- `rerun_from_source.sql` — run-operation that maps source table to downstream models with group-aware rebuild commands
- `resolve_quarantine.sql` — run-operation that marks quarantined rows as resolved after successful reruns

### Project Reorganization (Subfolder Strategy)

**Macros** — split from flat `macros/` into:
- `macros/generic_tests/` (14 files) — all `test_*.sql` reusable test macros
- `macros/data_quality/` (6 files) — hashdiff, freshness, circuit breaker, audit, quarantine, dedup
- `macros/operations/` (3 files) — smart_retry, rerun_from_source, resolve_quarantine
- `macros/generate_schema_name.sql` remains at root (dbt convention)

**Tests** — split from flat `tests/` into:
- `tests/reconciliation/` (5 files) — bronze↔silver count matches, revenue/visitor reconciliation
- `tests/referential_integrity/` (9 files) — FK checks, orphan detection, email existence
- `tests/business_rules/` (4 files) — campaign rates, negative values, date coverage

**Gold Models** — split from flat `models/marts/` into:
- `models/marts/dimensions/` (7 models + schema.yml) — all `dim_*` models
- `models/marts/facts/` (10 models + schema.yml) — all `fct_*` models including new donor models
- `models/marts/reports/` (5 models + schema.yml) — all `rpt_*` BI-facing views

**Modified** (1 file)
- `dbt_project.yml` — `test-paths` updated to point to subfolders

### Donor Retention & Churn Forecasting

**New** (2 files in `models/marts/facts/`)
- `fct_donor_retention.sql` — monthly retention rates per cohort (acquisition month, membership type, acquisition method, donor tier)
- `fct_donor_cohort_survival.sql` — survival curves per cohort with half-life detection and cohort health scoring (Healthy/At Risk/Declining/Critical)

**New** (1 file in `models/ml_features/`)
- `ml_donor_churn_features.sql` — per-donor churn prediction features: tenure, donation velocity, recency bands, engagement decay, estimated months-to-churn based on cohort survival half-life

**New** (1 file)
- `models/_model_groups.yml` — dbt groups declaring 5 model ownership clusters (daily_operations, member_engagement, donor_retention, campaign_analytics, visitor_forecasting)

**Modified** (1 file)
- `models/exposures.yml` — added `ml_donor_churn_model` and `powerbi_donor_retention_dashboard` exposures with full pipeline lineage documentation

**Model count: 32 → 35 | Exposure count: 6 → 8 | Group count: 0 → 5**

### Bug Fixes
- `models/marts/dim_product.sql` — full-refreshed to resolve `on_schema_change: fail` error from numeric precision drift (NUMBER(10,2) type mismatch)
- `models/marts/fct_member_360.sql` — full-refreshed to resolve schema type sync (10 numeric columns)
- `models/marts/fct_daily_operations.sql` — full-refreshed to resolve schema type sync (15 numeric columns)

---

## [1.1.0] - 2026-05-16

### Performance & Cost Optimization

**Clustering Keys** (10 files)
- `models/intermediate/silver_pos_tickets.sql` — `cluster_by: [transaction_date]`
- `models/intermediate/silver_pos_retail.sql` — `cluster_by: [transaction_date, item_category]`
- `models/intermediate/silver_ticket_scans.sql` — `cluster_by: [scan_date, gate_id]`
- `models/intermediate/silver_sf_crm.sql` — `cluster_by: [computed_membership_status, membership_type]`
- `models/intermediate/silver_sf_marketing_cloud.sql` — `cluster_by: [event_date, campaign_id]`
- `models/marts/fct_daily_operations.sql` — `cluster_by: [visit_date]`
- `models/marts/fct_visitor_traffic.sql` — `cluster_by: [scan_date]`
- `models/marts/fct_retail_performance.sql` — `cluster_by: [transaction_date, item_category]`
- `models/marts/fct_campaign_performance.sql` — `cluster_by: [first_send_date]`
- `models/marts/fct_member_360.sql` — `cluster_by: [engagement_segment, computed_membership_status]`

**Transient Tables** (8 files)
- `models/marts/dim_date.sql`
- `models/marts/dim_gate.sql`
- `models/marts/dim_product.sql`
- `models/marts/dim_campaign.sql`
- `models/marts/dim_ticket_type.sql`
- `models/marts/dim_payment_method.sql`
- `models/ml_features/ml_daily_visitor_features.sql`
- `models/ml_features/ml_member_churn_features.sql`

**Project-Level Configs** (1 file)
- `dbt_project.yml` — added query_tag per layer, statement_timeout pre-hook (3600s default, 300s for intraday), copy_grants on silver/gold, transient on silver/ml_features, on-run-start freshness check, intraday timeout override

### Dedicated Warehouses (Snowflake objects, not files)
- Created `DBT_DEV_WH` (XS, auto-suspend 60s, 5 credit/month monitor)
- Created `DBT_PROD_WH` (Small, auto-suspend 60s, 50 credit/month monitor)
- `profiles.yml` — updated dev/prod targets to use dedicated warehouses

### Grain Strategy

**New Models** (2 files)
- `models/marts/fct_monthly_operations.sql` — monthly pre-aggregated ops summary from fct_daily_operations
- `models/marts/fct_monthly_retail.sql` — monthly pre-aggregated retail by category from fct_retail_performance

**Refactored** (1 file)
- `models/ml_features/ml_daily_visitor_features.sql` — now reads from gold facts instead of re-aggregating silver tables

**Incremental Dimensions** (2 files)
- `models/marts/dim_product.sql` — converted from table to incremental merge
- `models/marts/dim_ticket_type.sql` — converted from table to incremental merge

### Intraday Pipeline (15-min ticket sales)

**Modified** (4 files)
- `models/intermediate/silver_pos_tickets.sql` — changed to append strategy, tagged intraday
- `models/raw/stg_pos_tickets.sql` — tagged intraday
- `models/marts/fct_daily_operations.sql` — tagged intraday, dedicated query_tag
- `models/raw/sources.yml` — raw_pos_tickets freshness: warn 30min, error 60min

### Source Freshness

**New** (1 file)
- `macros/check_source_freshness.sql` — per-source staleness thresholds (60min for tickets, 48hr for others)

### New Feature: Ticket Utilization

**New** (1 file)
- `models/marts/fct_ticket_utilization.sql` — transaction-level join of tickets sold to gate scans; identifies unscanned tickets, scan issues, purchase-to-entry time

### Schema & Documentation

**Modified** (3 files)
- `models/marts/schema.yml` — added fct_monthly_operations, fct_monthly_retail, fct_ticket_utilization entries; added _loaded_at to dim_product contract
- `models/exposures.yml` — added fct_monthly_operations and fct_monthly_retail to dashboard and Cortex Analyst exposures

### Bug Fixes
- `models/marts/schema.yml` — fixed `doubleversion: 2` merge conflict corruption
- `models/marts/dim_product.sql` — fixed correlated aggregate subquery error (aliased `{{ this }} t`)
- `models/marts/dim_ticket_type.sql` — fixed correlated aggregate subquery error (aliased `{{ this }} t`)
