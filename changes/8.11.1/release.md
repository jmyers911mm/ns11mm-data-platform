# 8.11.1: Disable narrative brief models

- **Date:** 2026-08-17
- **Version:** 8.11.1

## Changed

- **Disabled 8 narrative brief / card models** to reduce `dbt run` wall-clock time (all were
  causing unnecessary compute during dev builds):
  - `rpt_earned_income_variance_narrative_brief`
  - `rpt_retail_analysis_narrative_brief`
  - `rpt_daily_scan_narrative_brief`
  - `rpt_today_sales_narrative_brief`
  - `rpt_tracker_narrative_brief`
  - `rpt_donations_narrative_brief`
  - `rpt_attendance_narrative_brief`
  - `rpt_tracker_narrative_card`

- **`stg_memorial__attendance`** — fixed source reference: uses `ref('seed_memorial_attendance')`
  (SEEDS schema) instead of the non-existent `source('report_estate_seed', 'seed_memorial_attendance')`
  (RAW schema), and synthesizes `_loaded_at` via `current_timestamp()` to maintain the column
  contract.

- Removed phantom `seed_memorial_attendance` entry from `models/raw/sources.yml` (no
  corresponding table exists in RAW).
