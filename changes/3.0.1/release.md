# 3.0.1: Fix date_id → date_key in tests

- **Date:** 2026-07-21
- **Version:** 3.0.1

Renames all stale `date_id` references to `date_key` in dbt tests to align with
the `dim_date` model, which already exposes the column as `date_key`.

## Fixed

- `tests/reconciliation/assert_rpt_avg_ticket_price.sql` — 4 column references
  updated (`date_id` → `date_key`) for joins against `fct_daily_performance` and
  `rpt_daily_performance_report`.
- `tests/business_rules/assert_date_coverage.sql` — 4 column references updated
  to query `date_key` from `dim_date`.
- `tests/referential_integrity/assert_gold_daily_ops_no_orphan_dates.sql` — 2
  column references updated in the `dim_date` join and null check.

---
