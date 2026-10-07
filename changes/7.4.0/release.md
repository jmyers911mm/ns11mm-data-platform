# 7.4.0: Model Hygiene

- **Date:** 2026-07-29
- **Version:** 7.4.0

## Changed

- **Header standard completed** — the nine Power BI serving models
  (`rpt_*_powerbi`, `rpt_*_report_long`, `rpt_retail_category_long`, `rpt_*_budget_daily`)
  now carry the standard Layer/Domain/Grain/Feeds/ADR header; layer tokens normalized on the
  ML and narrative models; 78 AI-attribution comment lines stripped repo-wide;
  `rpt_daily_performance_report`'s table override documented with a MATERIALIZATION note.
- **Budget reports no longer self-source** — `rpt_dpr_budget_daily` / `rpt_retail_budget_daily`
  read the `fct_budget_*` models via `ref()` instead of a fake `source()` (DAG ordering and
  lineage restored); dead source blocks removed; `_budget_sources.yml` moved to `models/raw/`
  with the stg-bypass exception documented.
- **Facility literals removed from the new report family** — `rpt_retail_report_long`,
  `rpt_retail_narrative_brief`, `rpt_dpr_budget_daily` join `dim_facility` and key off
  `facility_group` instead of raw facility numbers (1:1 join on `key_facility`, same rows
  selected — a renumber no longer touches report SQL).
- **Deprecated `tests:` keys converted to `data_tests:`** with
  `dbt_utils.unique_combination_of_columns` replacing concatenated-column unique tests.
- **Severity rule applied both directions** — four GROUP-BY-enforced grain tests promoted
  warn → error (`int_retail__performance`'s grain combination also corrected to
  date × facility × category); `int_budget__*` uniques and `rpt_dpr_powerbi.report_date`
  demoted to warn (inherited/unverified grains).

## Added

- **schema.yml coverage for all 16 previously undocumented active models**, including
  `int_gateway__item_attributes` and `fct_today_sales_hourly`, and `rpt_wifi_email_export`
  documented as RESTRICTED/PII; `int_gateway__ticket_journal_lines.jnl_detail_id` finally
  has a `unique` test (warn) — the DPR backbone's grain was previously untested.
- `retail_line_items` and `seed_scan_market_segment` registered in `_seeds.yml` with tests
  (both actively consumed but previously unregistered); `ref_*` seeds marked as legacy
  deletion candidates.
- `fct_ticket_availability` NOTE documenting the 7-day-lookback vs 90-day-window constraint
  (monthly `--full-refresh` recommended); redundant `enabled=true` removed.

## Removed

- Eight ghost `tmp_seed_*` entries in `_seeds.yml` (no CSVs exist); `seeds/tmp_seed_dsr_budget.csv`
  (orphan); `pipelines/salesforce_mc/temp_pipeline.py` (contained a real SFMC tenant id and
  bypassed Key Vault). `alert_management.sql` moved to `scripts/`; `TEMP_POC_MIGRATION.md`
  moved to `docs/POC_MIGRATION_RECORD.md` as a marked historical record.

---
