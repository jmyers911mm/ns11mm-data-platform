# 1.3.0: Gateway & CounterPoint Seed Data Buildout

- **Date:** 2026-07-06
- **Version:** 1.3.0

## Added

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

## Changed

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

## Removed

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

## Disabled (`enabled=false`)

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
