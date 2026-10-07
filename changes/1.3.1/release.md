# 1.3.1: DPR Semantic View & Build Fixes

- **Date:** 2026-07-06
- **Version:** 1.3.1

## Added

**Semantic View**
- `NS11MM_DW_DEV_JMYERS.MARTS.DPR` — native Snowflake semantic view over FCT_DAILY_PERFORMANCE + DIM_DATE with 19 metrics (additive SUM + ratio-of-sums), 8 dimensions, AI instructions, and commemoration-window awareness
- `semantic_models/create_dpr_semantic_view.sql` — environment-portable DDL (USE DATABASE at top for dev/prod switch)
- `semantic_models/dpr.yaml` — Cortex Analyst YAML spec with verified queries and custom instructions

## Fixed

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

## Changed

- `models/intermediate/schema.yml` — removed schema entries for deleted models (`silver_pos_tickets`, `silver_pos_retail`, `silver_ticket_scans`, `silver_ticket_inventory`)
- `models/exposures.yml` — all 11 exposures removed (depend on disabled marts); placeholder comments retained

## Removed

- `analyses/create_marketing_semantic_view.sql` — deleted (referenced disabled models)
- `analyses/verified_queries/` — entire directory removed (49 files; no verified queries currently applicable)

---
