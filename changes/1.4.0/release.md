# 1.4.0: Ticket Demand Forecasting & ML Pipeline

- **Date:** 2026-07-07
- **Version:** 1.4.0

## New Models

- **`int_pos_tickets`** — daily POS ticket transactions from gateway tickets
- **`int_ticket_scans`** — gate scan events from gateway usage data
- **`int_ticket_inventory`** — derived daily ticket inventory (reservations vs rolling-90d-max capacity)
- **`fct_daily_operations`** — daily operational metrics (visitors, ticket sales, revenue); Shopify removed pending data
- **`fct_ticket_availability`** — ticket capacity and utilization by date/type (incremental)
- **`ml_ticket_demand_features`** — enabled; columns renamed (`entry_date→visit_date`, `daily_reserved→daily_visitors`) to align with Snowflake ML FORECAST
- **`ml_visitor_forecast_training`** — enabled; feeds visitor count forecasting

## Bug Fixes

- **CounterPoint staging models** (5 files) — added `_loaded_at` to staged CTE; was missing and caused `invalid identifier` errors in the `QUALIFY` deduplication clause
- **`stg_gateway__tickets`** — `ticket_date` now sourced from `endoflifedate` (the actual visit date in Galaxy); `ticketdate` column had 0 parseable values
- **`int_gateway__ticket_demand_features`** — added filter `ticket_date < '2030-01-01'` to exclude 15K sentinel `3000-12-31` rows (lifetime memberships)
- **`fct_ticket_availability`** — fixed `cluster_by` referencing `ticket_type_id` (should be `ticket_type`, the output alias)
- **`fct_daily_operations`** — fixed trailing comma after last CTE causing syntax error; fixed incremental `WHERE` referencing non-existent `_extracted_at` column in `{{ this }}`

## ML Forecasting

- **`create_ticket_demand_forecast` macro** — now target-aware (resolves from `target.database` instead of hard-coded PROD); added empty-table guard
- **`MANUAL_ML_RUN.sql`** — standalone SQL for running forecast outside dbt; includes filtered training view (series with 10+ observations) to avoid internal errors from single-point series
- **`ML_TICKET_DEMAND_FEATURES_FILTERED`** — view excluding series with <10 data points for stable model training

## Test Coverage Expansion

- **New `models/raw/schema.yml`** — PK tests (unique + not_null) for 12 staging models
- **Updated `models/intermediate/schema.yml`** — added tests for `int_pos_tickets`, `int_ticket_scans`, `int_ticket_inventory`, `int_gateway__ticket_demand_features`
- **Updated `models/marts/facts/schema.yml`** — added tests for `fct_daily_operations` (visit_date unique/not_null), `fct_ticket_demand_forecast`, `fct_ticket_availability`
- **Updated `models/ml_features/schema.yml`** — added `daily_visitors` not_null test; added `ml_visitor_forecast_training` tests (ds unique/not_null, y not_null)
- **New singular tests:**
  - `assert_critical_tables_not_empty` — fails if any of 6 critical tables has 0 rows
  - `assert_no_future_tickets` — flags implausible future dates in staging
  - `assert_no_negative_revenue` — re-enabled from disabled
  - `assert_gold_daily_ops_no_orphan_dates` — re-enabled from disabled
  - `assert_raw_silver_ticket_count_match` — re-enabled; fixed source (was `jnltickets`, now `tickets`); added `sold_at IS NOT NULL` filter
  - `assert_silver_gold_revenue_reconciliation` — re-enabled; fixed column name and removed stale date filter
- **Source freshness** — added `warn_after: 7 days` / `error_after: 14 days` to both `gateway_seed` and `counterpoint_seed`

## File Organization

- Moved 67 disabled files into `disabled/` subfolders:
  - `models/intermediate/disabled/` (8 files)
  - `models/marts/dimensions/disabled/` (6 files)
  - `models/marts/facts/disabled/` (20 files)
  - `models/marts/reports/disabled/` (9 files)
  - `models/ml_features/disabled/` (12 files)
  - `tests/business_rules/disabled/` (2 files)
  - `tests/reconciliation/disabled/` (2 files)
  - `tests/referential_integrity/disabled/` (4 files)

## Documentation

- Updated READMEs: root, `models/raw/`, `models/intermediate/`, `models/marts/facts/`, `models/ml_features/`, `macros/operations/`, `tests/business_rules/`, `tests/reconciliation/`, `tests/referential_integrity/`
- Root README current-scope table updated: 12 intermediate (was 8), 4 facts (was 1), 2 ML features (was 0)

---
