# 7.12.3: Retail Performance DirectQuery Serving (periods resolved in SQL)

- **Date:** 2026-08-07
- **Version:** 7.12.3

Extends the 7.12.1/7.12.2 DirectQuery approach to the Retail Performance Report. Its six
printed period columns x 3 scenarios x 34 line items is ~600 DAX time-intelligence cells —
the worst-case DQ workload. Jeremy's call: resolve the periods in dbt and let Power BI
render a dumb, fast grid.

## Added

- **rpt_retail_period_windows** — the six printed periods (Current Day / SDLY / WTD / MTD /
  QTD / YTD) authored ONCE as [start_date .. end_date] ranges. Anchored on the latest
  ACTUALS date before today, from `rpt_retail_powerbi` **not** `rpt_retail_report_long`:
  the budget side carries forward-dated forecast rows that would drag the anchor into the
  future and inflate every budget window. Consumed by both page models so the two pages
  cannot disagree about a period.
- **rpt_retail_report_periods** — page-1 grid, one row per (period_code, line_item_code)
  with `actual_value` / `budget_value` / `variance` / `variance_pct` resolved. Ratio lines
  divide sum(numerator)/sum(denominator) **within each window** — ratio-of-sums preserved,
  never an average of daily ratios. Variance blank-guarded (unbudgeted lines read NULL, not
  -100%). Component sums retained for audit.
- **rpt_retail_category_periods** — page-2 category grid over the same shared windows
  (additive only). Category budget stays NULL by design (facility-grain forecast).
- **rpt_retail_narrative_card** — deterministic ASCII analyst card rendered in SQL over
  rpt_retail_narrative_brief; binds as a plain view under DQ (twin of
  rpt_tracker_narrative_card). Works before T_RETAIL_NARRATIVE is resumed.

## Notes

- **Supersedes** the original Retail build spec's "do not materialize WTD/MTD/QTD/YTD in
  SQL" instruction, which assumed Import mode. The reason for that rule — ratio correctness
  at every period grain — is preserved by construction here.
- As-of snapshot models (~204 rows page 1): they emit the current reporting day only.
  History stays in rpt_retail_report_long / rpt_retail_category_long.
- Sign-off gate: validate the window definitions (SDLY = -364 days, Sunday-start WTD,
  calendar MTD/QTD/YTD) against the legacy .prpt, then reconcile the grid to a recent PDF.
