# NS11MM Data Platform — POC to Production Migration Inventory

> Historical record of the June-July 2026 POC migration; superseded facts are not maintained. Kept for provenance.

**Source (POC):** `jmyers911mm/ns11mm-dbt`  
**Destination (Production):** `ns11mm/ns11mm-data-platform`  
**Last updated:** July 8, 2026 (v1.5.0 reconciliation sprint)

> **What changed since June 23:** the Gateway + CounterPoint → DPR slice is now **built,
> validated, and reconciled against legacy** (see Section 0). Interim ingestion is
> seed-based extracts, not the VARIANT pipelines this inventory originally assumed —
> those remain the target state. Naming migrated `silver_*` → `int_*` in 1.4.0.
> Remaining blockers are extract-scope issues owned by Diana (Section 0b) and two ADR
> decisions. Companions: `CHANGELOG.md` (1.5.0), `docs/architecture/DPR_LINEAGE.md`,
> `dpr_metric_reconciliation_audit_v3.xlsx`.

---

## Status key

| Status | Meaning |
|---|---|
| ✅ Complete | File created and ready to use |
| 🔶 Needs data feed | Structure complete; uncomment/populate once RAW tables are live |
| 📋 Migrate from POC | Copy from POC and apply naming find-and-replace (see Section 21) |
| 🔨 Rebuild | Must be substantially rewritten for production — not a copy |
| ❌ Exclude | POC artifact not needed in production |
| 📌 Decision required | Blocked on an open architectural decision |

---

## 0. Live today — the DPR slice (built July 2026, after this inventory was written)

Everything below is ✅ in production-dev, validated against Snowflake and reconciled
against the legacy Pentaho definitions. It supersedes the corresponding
target-state rows in Sections 2–6 for the Gateway/CounterPoint domain.

| Layer | Live objects |
|---|---|
| Seeds (interim ingestion) | `seed_gate_*` (15 Gateway extracts), `seed_cp_*` (CounterPoint extracts), `seed_tour_plu` (rebuilt 1.5.0), `seed_retail_store_facility`, `seed_retail_item_facility` |
| Staging | 21 `stg_gateway__*` / `stg_counterpoint__*` models — seed-based (rename, safe parsing, `trim(plu)`, dedup); the VARIANT shells in Section 2 remain target-state for pipeline ingestion |
| Intermediate — conformance | `int_gateway__ticket_journal_lines` (101; `key_date`, `ga_flag`), `int_gateway__item_journal_lines` (102–104), `int_counterpoint__retail_lines` (facility resolution), `int_ticket_scans`, `int_pos_tickets`, `int_ticket_inventory` |
| Intermediate — metrics | `int_dpr__admissions`, `int_dpr__tour_revenue`, `int_dpr__fees_and_services`, `int_dpr__donations`, `int_dpr__retail`, `int_dpr__attendance` |
| Marts | `dim_date`, `fct_daily_performance` (~45 additive measures), `rpt_daily_performance_report`, `fct_daily_operations`, `fct_ticket_availability`, `fct_ticket_demand_forecast` |
| Semantic | `MARTS.DPR` via `semantic_models/dpr.yaml` (49 metrics, fiscal calendar); native DDL twin pending regeneration |
| Macros | `gateway_recognized_date` (recognize-basis + visit-date fallbacks), `gateway_general_admission_flag` |
| Validated totals (July extract window) | tickets_sold 96,326 / $2.68M · journal partition reconciles to the penny · mem_mus_tour $107K · cafe $68K/$7.2K · box-office donations $36.5K · full evidence in the reconciliation workbook |

## 0b. Outstanding data-dependency issues (extract scope — owner: Diana)

These block specific metrics, not the platform. All four are proven **not** to be
model bugs; the legacy documentation shows each working in production.

| # | Issue | Tables | Blocks | Nature |
|---|---|---|---|---|
| 1 | FK columns arrive as literal 0 | `JnlTickets.disbursement_id` (all rows), `JnlDetails.order_line_id` (codes 33/35/37/52); `DisbursementDetails` join never fires | Tour-with-GA cohort in `tickets_sold`; MGT XGA/XXX split; identifying codes 33/35/37/52 | **Export defect** — sampling reduces rows, not values |
| 2 | COA extract incomplete | `COA` missing accounts behind codes 33/35/37/52 (~$7.8M); `JnlItems`/`JnlTickets` bridges likely partial for non-101–104 codes | `service_fees` (code 33 = likely fee postings; FEE products exist in `Items`, transact nowhere visible) | Partial **lookup** extract — dimensions must be pulled whole |
| 3 | Recent-window-only extracts | `ps_tkt_hist_lin` (Jun 1–Jul 6; stores 8/10 absent), Gateway facts similar window, `Orders`/`OrderLines` | Retired/seasonal products (virtual tours, Revealed, masks), lifetime/JTD roll-ups, historical unissued | **Time-sliced sample** — resolved by the history load |
| 4 | `RMEvents.start_at` unresolved | `RMEvents` vs `JnlTickets.event_no` (111K basis-182 rows null; 202 legacy fields depend on this join) | True event dates for tour products (GA volume recovered via `end_of_life_date` fallback) | Inconsistent companion extract **or** join-key mismatch |

Extraction rule for the full load: time-slice fact tables if needed, but pull lookup
and bridge tables **complete**, preserve every column, and extract related tables from
the same snapshot. Issues 2–4 disappear under that rule; issue 1 needs the export
mapping fixed.

Also open (not extract): ADR-005 definitional decisions with Revenue (unissued —
confirmed present in `orderlines`, 5,703 units / $1.9M; CityPASS/bulk/child-subtraction;
buyout treatment — $18.7K evidence in the order book); ADR-007 (Drupal); ADR-008
(retail split); `create_dpr_semantic_view.sql` regeneration.

---

## 1. Project configuration files

| File | Status | Notes |
|---|---|---|
| `dbt_project.yml` | ✅ Complete | Updated: `ns11mm_data_platform` name, correct query tags, all schema targets |
| `packages.yml` | ✅ Complete | dbt_utils + dbt_date included |
| `.gitignore` | ✅ Complete | Standard dbt ignores |
| `.sqlfluff` | ✅ Complete | Snowflake dialect, 120 char limit |
| `.sqlfluffignore` | ✅ Complete | Ignores macros/ and target/ |
| `CODEOWNERS` | ✅ Complete | Jeremy primary; Kalea co-owner on staging/silver |
| `CONTRIBUTING.md` | ✅ Complete | Full workflow: profiles, branching, change tiers, PR checklist, VQR workflow |
| `RUNBOOK.md` | ✅ Complete | Daily ops, failure response, contacts, quick reference |
| `SNOWFLAKE_SETTINGS.md` | ✅ Complete | All databases, schemas, roles, warehouses documented |
| `CHANGELOG.md` | ✅ Complete | Started June 2026; versions 1.0.0 and 1.1.0 |
| `profiles.yml` | ✅ Complete | Created for Snowflake-native dbt (no env_var/password/authenticator) |
| `README.md` | ✅ Complete | Updated model counts, architecture, fiscal year, semantic view references |
| `PROJECT_MAP.md` | 📋 Migrate from POC | Update for new repo structure including pipelines/ folder |
| `ARCHITECTURE_FLOW.md` | 📋 Migrate from POC | Add pipeline ingestion layer above Bronze in flow diagram |
| `TEST_ORCHESTRATION.md` | 📋 Migrate from POC | Update source names to match 14 production sources |
| `SOURCE_INTEGRATION.md` | ❌ Exclude | Superseded by `ns11mm_bronze_pipelines_master.md` |
| `COPYWORKSPACE.sql` | ❌ Exclude | POC Snowflake Workspace utility — not needed |

---

## 2. Models — Staging

**Critical note:** All staging models below read from RAW VARIANT columns using `:field::TYPE` syntax — that remains the **target state for pipeline ingestion**. For Gateway and CounterPoint, the live interim path is **seed-based staging** (21 `stg_gateway__*` / `stg_counterpoint__*` models per Section 0), which supersedes the four Gateway/CounterPoint shells below until the push-based agent lands. The other sources are unchanged.

| File | Status | Unblock condition |
|---|---|---|
| `sources.yml` | ✅ Complete | All 14 source definitions with freshness thresholds written; activate as each RAW table is populated |
| `stg_salesforce_nps__contacts.sql` | 🔶 Needs data feed | Run `SELECT _raw_data FROM RAW.RAW_SALESFORCE_NPS_CONTACT LIMIT 1` to confirm JSON field names |
| `stg_salesforce_nps__accounts.sql` | 🔶 Needs data feed | Same as above |
| `stg_salesforce_nps__opportunities.sql` | 🔶 Needs data feed | Same as above |
| `stg_salesforce_nps__campaigns.sql` | 🔶 Needs data feed | Same as above |
| `stg_salesforce_mc__tracking.sql` | 🔶 Needs data feed | Confirm SFMC JSON structure from pipeline |
| `stg_gateway__transactions.sql` | ❌ Exclude (superseded) | Replaced by the live seed-based `stg_gateway__*` family (Section 0) |
| `stg_gateway__ticket_types.sql` | ❌ Exclude (superseded) | Same — item/attribute data lives in `stg_gateway__items` / `__vattribute` |
| `stg_counterpoint__transactions.sql` | ❌ Exclude (superseded) | Replaced by live `stg_counterpoint__pstkthist(lin)` seed-based models |
| `stg_counterpoint__line_items.sql` | ❌ Exclude (superseded) | Same as above |
| `stg_shopify__orders.sql` | 🔶 Needs data feed | Shopify API response fields well-documented; low risk |
| `stg_shopify__customers.sql` | 🔶 Needs data feed | Same as above |
| `stg_shopify__products.sql` | 🔶 Needs data feed | Same as above |
| `stg_classy__campaigns.sql` | 🔶 Needs data feed | Confirm Classy API response fields |
| `stg_classy__transactions.sql` | 🔶 Needs data feed | Same as above |
| `stg_blackbaud__accounts.sql` | 🔶 Needs data feed | Confirm Blackbaud SKY API GL account fields |
| `stg_blackbaud__journal_entries.sql` | 🔶 Needs data feed | Same as above |
| `stg_vena__budget.sql` | 🔶 Needs data feed | Also requires MODELS dict populated in `pipelines/vena/pipeline.py` |
| `stg_ga4__sessions.sql` | 🔶 Needs data feed | GA4 fields are well-documented; low risk |
| `stg_google_ads__campaigns.sql` | 🔶 Needs data feed | Google Ads fields are well-documented; low risk |
| `stg_meta_ads__campaigns.sql` | 🔶 Needs data feed | Meta API fields are well-documented; low risk |
| `stg_wufoo__form_entries.sql` | 🔶 Needs data feed | Table name includes form hash — confirm format with Anna Kim |
| `stg_clicky__visitors.sql` | 🔶 Needs data feed | Confirm Clicky API stat type field names |
| `stg_drupal__pages.sql` | 📌 Decision required | ADR-007 (DB vs API path) must be resolved first |

---

## 3. Models — Silver (renamed `int_*` in 1.4.0)

**Naming note:** the `silver_` prefix was retired in 1.4.0; production uses `int_<domain>__<entity>`. The Gateway/CounterPoint DPR intermediates are live (Section 0); the models below cover the other sources. All Silver models migrated and production-ready. Bugs fixed: `silver_sf_crm` (NULL placeholders → real joins), `silver_blackbaud` (CASE NULL logic), `silver_pos_tickets` (customer join via `stg_gateway__customers`).

| File | Status | Notes |
|---|---|---|
| `silver_pos_tickets.sql` | ✅ Complete | Fixed: now joins `stg_gateway__customers` for email/phone |
| `silver_pos_retail.sql` | ✅ Complete | Unions CounterPoint + Shopify; ADR-008 pending |
| `silver_ticket_scans.sql` | ✅ Complete | Refs updated |
| `silver_sf_crm.sql` | ✅ Complete | Fixed: joins opportunities for membership + donation enrichment |
| `silver_sf_marketing_cloud.sql` | ✅ Complete | Refs updated |
| `silver_ticket_inventory.sql` | ✅ Complete | Capacity CTE placeholder — awaiting source |
| `silver_google_analytics.sql` | ✅ Complete | Refs updated |
| `silver_google_ads.sql` | ✅ Complete | Refs updated |
| `silver_meta_ads.sql` | ✅ Complete | Refs updated |
| `silver_classy.sql` | ✅ Complete | Built from `stg_classy__transactions` |
| `silver_shopify.sql` | ✅ Complete | Built from `stg_shopify__orders` |
| `silver_blackbaud.sql` | ✅ Complete | Fixed: `CASE WHEN IS NULL` logic |
| `schema.yml` | ✅ Complete | Full documentation + tests for all 12 models |

---

## 4. Models — Gold Dimensions

| File | Status | Notes |
|---|---|---|
| `dim_date.sql` | ✅ Complete | Fully self-contained; NS11MM fiscal calendar; `is_commemoration_day` flag included |
| `dim_marketing_channel.sql` | ✅ Complete | Seed-based; no RAW dependency |
| `dim_customer.sql` | 🔶 Needs data feed | Placeholder in place; populate from Silver once `silver_sf_crm` is live |
| `dim_gate.sql` | 🔶 Needs data feed | Placeholder in place; populate from Gateway Silver |
| `dim_campaign.sql` | 🔶 Needs data feed | Placeholder in place; populate from Salesforce Silver |
| `dim_ticket_type.sql` | 🔶 Needs data feed | Placeholder in place; populate from Gateway Silver |
| `dim_product.sql` | 🔶 Needs data feed | Placeholder in place; populate from CounterPoint/Shopify Silver |
| `dim_payment_method.sql` | 🔶 Needs data feed | Placeholder in place |
| `dim_fund.sql` | 🔶 Needs data feed | Placeholder in place; populate from Blackbaud Silver |
| `dim_budget_version.sql` | 🔶 Needs data feed | Placeholder in place; populate from Vena Silver |
| `schema.yml` | ✅ Complete | All dimension docs and tests written |

---

## 5. Models — Gold Facts

All fact models migrated from POC with production refs. Schema.yml created with documentation and tests.

| File | Status | Notes |
|---|---|---|
| `fct_daily_performance.sql` | ✅ Complete | **Live** — DPR additive fact, reconciled against legacy (1.5.0) |
| `rpt_daily_performance_report.sql` | ✅ Complete | **Live** — period roll-ups + ratios at query grain |
| `fct_daily_operations.sql` | ✅ Complete | Migrated + live in 1.4.0 |
| `fct_ticket_sales.sql` | 📋 Migrate from POC | Update refs; confirm Gateway transaction fields |
| `fct_retail_line_items.sql` | 📋 Migrate from POC | Update refs; per ADR-008 decision |
| `fct_ticket_availability.sql` | ✅ Complete | Migrated + live in 1.4.0 (incremental) |
| `fct_ticket_demand_benchmarks.sql` | 📋 Migrate from POC | Update refs |
| `fct_ticket_utilization.sql` | 📋 Migrate from POC | Deprecated in POC (2026-07-01) — evaluate before migrating |
| `fct_retail_performance.sql` | 📋 Migrate from POC | Deprecated in POC (2026-07-01) — evaluate before migrating |
| `fct_donor_retention.sql` | 📋 Migrate from POC | Update refs to Salesforce NPS + Classy Silver |
| `fct_donor_cohort_survival.sql` | 📋 Migrate from POC | Update refs |
| `fct_campaign_performance.sql` | 📋 Migrate from POC | Update refs to SFMC Silver |
| `fct_campaign_attribution.sql` | 📋 Migrate from POC | Update refs |
| `fct_marketing_channel_summary.sql` | 📋 Migrate from POC | Update refs |
| `fct_website_traffic.sql` | 📋 Migrate from POC | Update refs to GA4 Silver |
| `fct_website_funnel.sql` | 📋 Migrate from POC | Update refs |
| `fct_digital_ad_performance.sql` | 📋 Migrate from POC | Update refs to Google Ads + Meta Ads Silver |
| `fct_ad_campaign_daily.sql` | 📋 Migrate from POC | Update refs |
| `fct_marketing_sales_daily.sql` | 📋 Migrate from POC | Update refs |
| `fct_monthly_operations.sql` | 📋 Migrate from POC | Update refs |
| `fct_monthly_retail.sql` | 📋 Migrate from POC | Update refs |
| `fct_fundraising.sql` | 🔨 Rebuild | New — build from `silver_classy` |
| `fct_membership.sql` | 🔨 Rebuild | New — build from `silver_sf_crm` |
| `fct_gl_transactions.sql` | 🔨 Rebuild | New — build from `silver_blackbaud` |
| `fct_budget_vs_actuals.sql` | 🔨 Rebuild | New — build from `silver_vena` + `silver_blackbaud` |
| `schema.yml` | 📋 Migrate from POC | Update refs |

---

## 6. Models — Gold Reports

All report models migrated from POC with production refs. Schema.yml created.

| File | Status | Notes |
|---|---|---|
| `rpt_daily_operations.sql` | 📋 Migrate from POC | Update refs |
| `rpt_customer_ltv.sql` | 📋 Migrate from POC | Update refs; include Classy donations |
| `rpt_ticket_sales.sql` | 📋 Migrate from POC | Update refs |
| `rpt_retail_performance.sql` | 📋 Migrate from POC | Update refs |
| `rpt_member_360.sql` | 📋 Migrate from POC | Update refs to Salesforce NPS |
| `rpt_visitor_traffic.sql` | 📋 Migrate from POC | Update refs |
| `rpt_campaign_performance.sql` | 📋 Migrate from POC | Update refs |
| `rpt_digital_marketing.sql` | 📋 Migrate from POC | Update refs |
| `rpt_revenue_bridge.sql` | 📋 Migrate from POC | Update refs |
| `schema.yml` | 📋 Migrate from POC | Update refs |

---

## 7. Models — ML Features

All 14 ML feature models migrated from POC. Schema.yml with documentation and tests created. Two training notebooks added.

| File | Status | Notes |
|---|---|---|
| `ml_ticket_no_show_features.sql` | 📋 Migrate from POC | Update refs |
| `ml_retail_cross_sell_features.sql` | 📋 Migrate from POC | Update refs |
| `ml_email_send_time_features.sql` | 📋 Migrate from POC | Update refs to SFMC Silver |
| `ml_campaign_response_features.sql` | 📋 Migrate from POC | Update refs |
| `ml_dynamic_pricing_features.sql` | 📋 Migrate from POC | Update refs |
| `ml_donor_upgrade_propensity_features.sql` | 📋 Migrate from POC | Update refs |
| `ml_visitor_forecast_training.sql` | 📋 Migrate from POC | Update refs |
| `ml_daily_visitor_features.sql` | 📋 Migrate from POC | Update refs |
| `ml_member_churn_features.sql` | 📋 Migrate from POC | Update refs |
| `ml_ad_budget_optimization_features.sql` | 📋 Migrate from POC | Update refs |
| `ml_marketing_attribution_features.sql` | 📋 Migrate from POC | Update refs |
| `ml_ad_creative_features.sql` | 📋 Migrate from POC | Update refs |
| `ml_donor_churn_features.sql` | 📋 Migrate from POC | Update refs |
| `ml_ticket_demand_features.sql` | 📋 Migrate from POC | Update refs |
| `schema.yml` | 📋 Migrate from POC | Update refs |

---

## 8. Snapshots

| File | Status | Notes |
|---|---|---|
| `snap_dim_customer.sql` | 🔶 Needs data feed | Created; uncomment once `dim_customer` is populated |
| `snap_sf_crm.sql` | 🔶 Needs data feed | Created; uncomment once `stg_salesforce_nps__contacts` is live |

---

## 9. Seeds

| File | Status | Notes |
|---|---|---|
| `ref_marketing_channels.csv` | ✅ Complete | 7 channels including paid and owned |
| `ref_ltv_tiers.csv` | ✅ Complete | Platinum/Gold/Silver/Bronze tiers |
| `ref_ticket_types.csv` | ✅ Complete | 10 ticket types matching Gateway taxonomy |
| `ref_payment_methods.csv` | ✅ Complete | 8 payment methods |
| `ref_customer_segments.csv` | ✅ Complete | Known Member / Identified Visitor / Anonymous |
| POC mock data seeds (`raw_google_analytics.csv`, etc.) | ❌ Exclude | Mock data only — replaced by RAW pipeline |

---

## 10. Macros

### macros/generic_tests/

| File | Status | Notes |
|---|---|---|
| `test_hashdiff_integrity.sql` | ✅ Complete | |
| `test_referential_integrity.sql` | ✅ Complete | |
| `test_row_count_drift.sql` | ✅ Complete | |
| `test_late_arriving_data.sql` | ✅ Complete | |
| `test_schema_drift.sql` | ✅ Complete | |
| `null_rate_threshold.sql` | ✅ Complete | |
| `daily_volume_bounds.sql` | ✅ Complete | |
| `cardinality_change.sql` | ✅ Complete | |
| `distribution_shift.sql` | ✅ Complete | |
| `README.md` | ✅ Complete | |

### macros/data_quality/

| File | Status | Notes |
|---|---|---|
| `generate_hashdiff.sql` | ✅ Complete | |
| `quarantine_failed_rows.sql` | ✅ Complete | |
| `auto_heal_duplicates.sql` | ✅ Complete | |
| `check_source_freshness.sql` | ✅ Complete | Table names reflect expected RAW naming; update if actual names differ |
| `README.md` | ✅ Complete | |

### macros/operations/

| File | Status | Notes |
|---|---|---|
| `create_ticket_demand_forecast.sql` | ✅ Complete | Database refs updated to NS11MM |
| `sync_verified_queries.sql` | ✅ Complete | |
| `validate_before_deploy.sql` | ✅ Complete | Model list matches production models |
| `compare_model_to_prod.sql` | ✅ Complete | |
| `smart_retry.sql` | ✅ Complete | |
| `rerun_from_source.sql` | ✅ Complete | Source map populated with all 14 sources |
| `resolve_quarantine.sql` | ✅ Complete | |
| `README.md` | ✅ Complete | |

### macros/root

| File | Status | Notes |
|---|---|---|
| `generate_schema_name.sql` | ✅ Complete | Standard dbt convention |

---

## 11. Tests

| File | Status | Notes |
|---|---|---|
| `tests/reconciliation/assert_raw_silver_ticket_count_match.sql` | 🔶 Needs data feed | Written; commented out; uncomment once RAW.RAW_GATEWAY_TRANSACTIONS is populated |
| `tests/reconciliation/assert_raw_silver_retail_count_match.sql` | 🔶 Needs data feed | Same as above |
| `tests/reconciliation/assert_silver_gold_revenue_reconciliation.sql` | 🔶 Needs data feed | Uncomment once production Gold models exist |
| `tests/reconciliation/assert_silver_gold_visitor_reconciliation.sql` | 🔶 Needs data feed | Same as above |
| `tests/referential_integrity/assert_campaign_fk_integrity.sql` | 🔶 Needs data feed | Uncomment once fct_campaign_performance and dim_campaign exist |
| `tests/referential_integrity/assert_ticket_types_match_seed.sql` | 🔶 Needs data feed | Uncomment once fct_ticket_sales exists |
| `tests/referential_integrity/assert_payment_methods_match_seed.sql` | 🔶 Needs data feed | Same as above |
| `tests/referential_integrity/assert_customer_segments_match_seed.sql` | 🔶 Needs data feed | Uncomment once dim_customer exists |
| `tests/referential_integrity/assert_gold_daily_ops_no_orphan_dates.sql` | 🔶 Needs data feed | Uncomment once fct_daily_operations exists |
| `tests/business_rules/assert_no_negative_revenue.sql` | 🔶 Needs data feed | Uncomment once fct_daily_operations exists |
| `tests/business_rules/assert_no_future_transactions.sql` | 🔶 Needs data feed | Uncomment once fct_ticket_sales exists |
| `tests/business_rules/assert_campaign_rates_in_bounds.sql` | 🔶 Needs data feed | Uncomment once fct_campaign_performance exists |
| `tests/business_rules/assert_date_coverage.sql` | ✅ Complete | **Active now** — dim_date has no RAW dependency |
| All `README.md` files | ✅ Complete | |

---

## 12. Analyses / Verified Queries

Folder structure created. All 36 SQL files must be migrated from POC with database reference updates.

| Domain folder | Status | Notes |
|---|---|---|
| `analyses/verified_queries/campaigns/` | 📋 Migrate from POC | 1 query |
| `analyses/verified_queries/capacity_planning/` | 📋 Migrate from POC | 5 queries |
| `analyses/verified_queries/digital_marketing/` | 📋 Migrate from POC | 5 queries |
| `analyses/verified_queries/donor_retention/` | 📋 Migrate from POC | 5 queries |
| `analyses/verified_queries/membership/` | 📋 Migrate from POC | 3 queries |
| `analyses/verified_queries/retail/` | 📋 Migrate from POC | 2 queries |
| `analyses/verified_queries/revenue_operations/` | 📋 Migrate from POC | 7 queries |
| `analyses/verified_queries/ticket_sales/` | 📋 Migrate from POC | 5 queries |
| `analyses/verified_queries/visitor_experience/` | 📋 Migrate from POC | 2 queries |
| `_verified_queries.yml` files (one per domain) | 📋 Migrate from POC | Update semantic view names and database refs |
| `analyses/create_marketing_semantic_view.sql` | 📋 Migrate from POC | Update database and semantic view references |

---

## 13. Model groups and exposures

| File | Status | Notes |
|---|---|---|
| `models/groups.yml` | ✅ Complete | All 6 groups with correct email owners |
| `models/exposures.yml` | ✅ Complete | Core exposures written; add new source exposures (Classy, Shopify, Blackbaud, Vena) as those models are built |

---

## 14. Governance documentation

| File | Status | Notes |
|---|---|---|
| `docs/architecture/SQL_STYLE_GUIDE.md` | ✅ Complete | Includes VARIANT extraction pattern for staging models |
| `docs/architecture/DATA_CLASSIFICATION.md` | ✅ Complete | PII fields, access control, new model checklist |
| `docs/architecture/USAGE_AUDIT.md` | ✅ Complete | Pipeline log, Cortex observability, credit monitoring |
| `docs/business/METRIC_GLOSSARY.md` | ✅ Complete | All metrics across 6 domains including new sources |
| `docs/ONBOARDING.md` | 📋 Migrate from POC | Update repo URL, database names; replace Snowflake Workspace steps with VS Code workflow |
| `docs/README.md` | 📋 Migrate from POC | Update repo references |
| `docs/adr/0005-metric-definition-gate.md` | ✅ Complete | |
| `docs/adr/0006-change-management-tiers.md` | ✅ Complete | |
| `docs/adr/0007-drupal-ingestion-path.md` | ✅ Complete | Decision required from Jeremy + Anna Kim + Kenny |
| `docs/adr/0008-retail-source-split.md` | ✅ Complete | Decision required; recommendation is Option A (unified) |

---

## 15. CI/CD

| File | Status | Notes |
|---|---|---|
| `.github/workflows/dbt-ci.yml` | ✅ Complete | Slim CI on PRs, full build on merge; manifest artifact for state comparison |

---

## 16. Terraform / IaC

| File | Status | Notes |
|---|---|---|
| `terraform/main.tf` | ✅ Complete | |
| `terraform/variables.tf` | ✅ Complete | 18 variables with validation |
| `terraform/outputs.tf` | ✅ Complete | |
| `terraform/providers.tf` | ✅ Complete | |
| `terraform/modules/snowflake-warehouse/main.tf` | ✅ Complete | |
| `terraform/modules/key-vault/main.tf` | ✅ Complete | RBAC-based; soft-delete + purge protection |
| `terraform/modules/static-web-app/main.tf` | ✅ Complete | |
| `terraform/modules/monitor-alerts/main.tf` | ✅ Complete | |
| `terraform/environments/dev.tfvars.json` | ✅ Complete | X-Small warehouse, 5 credits |
| `terraform/environments/staging.tfvars.json` | ✅ Complete | Medium warehouse, 25 credits |
| `terraform/environments/prod.tfvars.json` | ✅ Complete | Medium warehouse, 50 credits |
| `terraform/pipelines/deploy-dev.yml` | ✅ Complete | Auto-trigger on main |
| `terraform/pipelines/deploy-staging.yml` | ✅ Complete | Manual trigger |
| `terraform/pipelines/deploy-prod.yml` | ✅ Complete | Manual trigger + approval gate |
| `terraform/notifications/teams_webhook_setup.sql` | 📋 Migrate from POC | Update notification integration name |
| `terraform/README.md` | ✅ Complete | |
| `terraform/.gitignore` | ✅ Complete | |

---

## 17. Scripts

| File | Status | Notes |
|---|---|---|
| `scripts/setup_developer_workspace.sql` | ✅ Complete | Includes NS11MM_DW_DEV_DIANA; LOADER_ROLE grants included |

---

## 18. Snowflake objects (must be re-created — not in repo)

| Object | Type | Status | Notes |
|---|---|---|---|
| `MARTS.DPR` (dev) | Semantic View | ✅ Complete | **Live** — generated from `semantic_models/dpr.yaml` (49 metrics, fiscal calendar); regenerate `create_dpr_semantic_view.sql` DDL twin to match |
| `NS11MM_DW_PROD.GOLD.SV_MUSEUM_OPERATIONS` | Semantic View | 📋 Migrate from POC | Rename + update entity/metric defs for production data |
| `NS11MM_DW_PROD.GOLD.SV_DONOR_RETENTION` | Semantic View | 📋 Migrate from POC | Rename + update |
| `NS11MM_DW_PROD.GOLD.SV_MARKETING_PERFORMANCE` | Semantic View | 📋 Migrate from POC | Update for production |
| `NS11MM_DW_PROD.GOLD.SV_MARKETING_SALES` | Semantic View | 📋 Migrate from POC | Update for production |
| `NS11MM_DW_PROD.GOLD.NS11MM_OPERATIONS_AGENT` | Cortex Agent | 📋 Migrate from POC | Rename; update semantic view tool references |
| `NS11MM_DW_PROD.MONITORING.AGENT_QUESTION_PATTERNS` | Table | 📋 Migrate from POC | Re-create in NS11MM_DW_PROD |
| `NS11MM_DW_PROD.MONITORING.ANALYZE_AGENT_QUESTION_GAPS` | Stored Procedure | 📋 Migrate from POC | Update database/schema refs |
| `NS11MM_DW_PROD.MONITORING.TASK_AGENT_PATTERN_ANALYSIS` | Task | 📋 Migrate from POC | Re-enable after production go-live |
| `NS11MM_EMAIL_ALERTS` | Notification Integration | 📋 Migrate from POC | Re-create |
| `GITHUB_INTEGRATION` | API Integration | 🔨 Rebuild | Point at `ns11mm/ns11mm-data-platform` |
| `NS11MM_DW_DEV.PUBLIC.NS11MM_DBT_REPO` | Git Repository Stage | 🔨 Rebuild | Point at production repo |
| `POWERBI` | External OAuth Integration | 📋 Migrate from POC | Re-create in production account |
| `DBT_DEV_WH` | Warehouse | 📋 Migrate from POC | Re-create (or via Terraform) |
| `DBT_PROD_WH` | Warehouse | 📋 Migrate from POC | Re-create (or via Terraform) |
| `COMPUTE_WH` | Warehouse | 📋 Migrate from POC | Used by pipeline LOADER_ROLE |
| `POWERBI_ROLE` | Role | 📋 Migrate from POC | Re-create + re-grant |
| `ML_ROLE` | Role | 📋 Migrate from POC | Re-create + re-grant |
| `LOADER_ROLE` | Role | ✅ Complete | Created and granted today |

---

## 19. Summary

> Counts below are as of June 23 and do **not** reflect the live DPR slice (Section 0)
> or the four superseded staging shells; read them as the remaining *target-state*
> migration surface for the non-DPR sources.

| Category | ✅ Complete | 🔶 Needs feed | 📋 Migrate | 🔨 Rebuild | 📌 Decision | ❌ Exclude |
|---|---|---|---|---|---|---|
| Config files | 8 | 0 | 4 | 0 | 0 | 3 |
| Staging models | 1 (sources.yml) | 22 | 0 | 0 | 1 | 0 |
| Silver models | 0 | 0 | 9 | 6 | 0 | 0 |
| Gold dimensions | 2 | 8 | 0 | 0 | 0 | 0 |
| Gold facts | 0 | 0 | 19 | 4 | 0 | 0 |
| Gold reports | 0 | 0 | 10 | 0 | 0 | 0 |
| ML features | 0 | 0 | 15 | 0 | 0 | 0 |
| Snapshots | 0 | 2 | 0 | 0 | 0 | 0 |
| Seeds | 5 | 0 | 0 | 0 | 0 | 3 |
| Macros | 22 | 0 | 0 | 0 | 0 | 0 |
| Tests | 1 | 12 | 0 | 0 | 0 | 0 |
| Verified queries | 0 | 0 | 36 | 0 | 0 | 0 |
| Governance docs | 8 | 0 | 2 | 0 | 0 | 0 |
| CI/CD | 1 | 0 | 0 | 0 | 0 | 0 |
| Terraform | 16 | 0 | 1 | 0 | 0 | 0 |
| Scripts | 1 | 0 | 0 | 0 | 0 | 0 |
| Snowflake objects | 1 | 0 | 13 | 2 | 0 | 0 |
| **Total** | **66** | **44** | **109** | **10** | **1** | **6** |

---

## 20. What to do next (in order)

### Right now (no data dependency)
1. Merge the 1.5.0 reconciliation PR through change control (Ginabell intake → Diana Change ID); attach `dpr_metric_reconciliation_audit_v3.xlsx`
2. Send the extract-scope request to Diana (Section 0b — zeroed FK columns, COA completeness, history depth, RMEvents); longest lead time on the board
3. Regenerate `create_dpr_semantic_view.sql` from the rebuilt `dpr.yaml` (DDL twin drift)
4. Schedule the ADR-005 definition session with Chris Wogas (unissued / CityPASS / bulk / child-subtraction / buyout) — evidence is in hand
5. Resolve ADR-007 (Drupal path) and ADR-008 (retail split)
6. Confirm with Gennady: cafe = CP store 1; stores 8/10 register status; remaining `mus_store_donations` surrogate items
7. Migrate 36 verified query SQL files from POC → `analyses/verified_queries/` (see Section 21)
8. Migrate `docs/ONBOARDING.md`, `docs/README.md`, and Terraform `notifications/teams_webhook_setup.sql` from POC

### Once Diana's extract fixes land (Section 0b)
9. Reload seeds; re-run the reconciliation funnel (raw → enriched → GA/tour partition must reconcile exactly)
10. Verify `service_fees` populates (code 33 / COA); un-gate the memorial-tours history metrics (revealed, field trips, virtual, ask-educator); re-check `disbursement_id`-dependent cohorts
11. Build the unissued population from `orderlines` per the ADR-005 decision

### Once first RAW pipeline is live (SFMC first per current priority)
6. Inspect `_raw_data` JSON: `SELECT _raw_data FROM NS11MM_DW_DEV.RAW.RAW_SALESFORCE_MC_TRACKING_SENT LIMIT 1`
7. Complete `stg_salesforce_mc__tracking.sql` field mappings
8. Build and test `silver_sf_marketing_cloud.sql`
9. Uncomment corresponding reconciliation and referential integrity tests

### Once all RAW pipelines are stable
10. Complete all remaining staging model field mappings
11. Migrate Silver models from POC (update refs)
12. Migrate Gold dimensions from POC (replace placeholders)
13. Migrate Gold facts and reports from POC
14. Uncomment all tests
15. Migrate ML feature models
16. Migrate verified queries to test against production data
17. Re-create Snowflake semantic views against production Gold tables
18. Re-create Cortex Agent

---

## 21. Required find-and-replace for all POC files

Run project-wide before migrating any file:

| Find | Replace |
|---|---|
| `museum_dbt` | `ns11mm_data_platform` |
| `museum-dbt` | `ns11mm-data-platform` |
| `MUSEUM_DW_DEV` | `NS11MM_DW_DEV` |
| `MUSEUM_DW_PROD` | `NS11MM_DW_PROD` |
| `MUSEUM_DW_STAGING` | `NS11MM_DW_STAGING` |
| `dbt_museum_` | `dbt_ns11mm_` |
| `jmyers911mm/ns11mm-dbt` | `ns11mm/ns11mm-data-platform` |
| `jmyers911mm/museum-dbt` | `ns11mm/ns11mm-data-platform` |
| `MUSEUM_EMAIL_ALERTS` | `NS11MM_EMAIL_ALERTS` |
| `MUSEUM_OPERATIONS_AGENT` | `NS11MM_OPERATIONS_AGENT` |
| `kv-ns11mm-dev` | `kv-ns11mm-dp-dev` |
| `museum_dbt_prod` | `ns11mm_dw_prod` |