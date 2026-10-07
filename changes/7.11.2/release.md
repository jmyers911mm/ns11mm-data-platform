# 7.11.2: Patch: Semantic-View Name Shadowing (supersedes 7.11.1's alias)

- **Date:** 2026-07-31
- **Version:** 7.11.2

7.11.1's fact alias failed with "Cyclic reference of expressions is not allowed:
[DP.ADMISSION_REVENUE_VALUE, DP.TOTAL_ADMISSION_REVENUE]" — proving the full rule: a
semantic-view **metric name shadows the same-named base column in EVERY expression in
the view** (facts included), so no expression can reach the column while the metric
carries its name. The metric name is public (Power BI wrapper, Cortex queries), so the
name stays and the view restates the components — with a dbt reconciliation test as the
drift guard the review originally wanted.

## Fixed

- **DPR.sv.yaml** — fact alias removed; `TOTAL_ADMISSION_REVENUE` authored as
  `SUM(TICKET_REVENUE) + SUM(PASS_REVENUE)` with the engine limitation and the guard
  test documented in the metric description. `AVG_TICKET_PRICE` stays metric-over-metric
  (unchanged from 7.11.1 — that part deployed correctly).
- **UNIFIED.sv.yaml** — `total_admission_revenue` reverted to the component sum for the
  same reason (identifiers are case-insensitive, so its lowercase metric name collides
  with the column too; 7.8.0's `SUM(TOTAL_ADMISSION_REVENUE)` there would have failed
  the same way on deploy).
- **New test `assert_sv_admission_revenue_matches_fct`** (error): day-grain equality
  between `rpt_dpr_powerbi.admission_revenue` (via the deployed semantic view) and the
  governed `fct_daily_performance.total_admission_revenue`. This is the enforcement
  that replaces "sum the column": if the fct definition ever changes, this test fails
  the same day and points at the two sv.yamls.
- Both DDLs regenerated; `--check` green.

## Migration notes

Re-run `scripts/deploy_semantic_view_dpr.sql` and `deploy_semantic_view_unified.sql`
(after `USE DATABASE <target>`) per database. Then `dbt test --select
assert_sv_admission_revenue_matches_fct` to confirm the guard passes.

---
