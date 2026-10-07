# 7.12.0: Reports 6–8 Serving Stack (Attendance · Carts Analysis · Website Commerce)

- **Date:** 2026-08-04
- **Version:** 7.12.0

Serving + narrative layer for the remaining Pentaho migrations, on the exact pattern of the
five built reports (tidy report_long with ratio components, line-item seed + dim, deterministic
brief → gated Cortex narrative → task setup script; periods in DAX, never SQL — ADR-004).

## Added

- **Attendance Report stack** — `rpt_attendance_report_long` (day × line item; all additive,
  no goals; also serves the single-figure Daily Attendance Report as a card on
  MUS_ATTENDANCE), `attendance_line_items` seed + `dim_attendance_line_item`
  (Sensource-backed lines marked Stub), `rpt_attendance_narrative_brief` +
  `rpt_attendance_narrative` (gated) + `scripts/setup_attendance_narrative.sql`
  (T_ATTENDANCE_NARRATIVE → ATTENDANCE_PBI_NARRATIVE).
- **Retail Carts Analysis stack** — `rpt_carts_report_long` (ratio lines carry
  numerator/denominator so the workbook's monthly views are ratio-of-sums, never averaged
  daily ratios; the legacy adjusted-visitor denominator components are carried additively),
  `carts_line_items` seed + `dim_carts_line_item` (visitor-derived lines Stub pending
  Sensource), `rpt_carts_narrative_brief` + `rpt_carts_narrative` (gated) +
  `scripts/setup_carts_narrative.sql` (T_CARTS_NARRATIVE → CARTS_PBI_NARRATIVE). Capture
  rate and per-caps are excluded from the brief while their denominator is a stub.
- **Website Commerce serving** — `rpt_website_commerce_daily` (day × revenue_type;
  supersedes the month-pivot for the PBI rebuild — pivot moves to a Power BI matrix over
  dim_date) and `rpt_website_commerce_detail` ("Donations By Date", day × title, no PII
  projected). `is_recurring` is TRUE on every row today: only the recurring feed is live;
  the one-time website feed is a documented open seam. No narrative chain — monthly
  cadence does not warrant a daily note; revisit if the report becomes a daily subscription.

## Documented (no code)

- **DPR Excel variants need no new models**: "DPR Excel Data" binds to `rpt_dpr_powerbi` +
  `rpt_dpr_budget_daily`; the MTD/YTD prior-year workbooks are DAX
  (`SAMEPERIODLASTYEAR` over `rpt_dpr_report_long`) — added to the build notes.
- README / report_semantic_view_map rows for the new stacks.

## Fixed

- `dbt_project.yml` version was left at 7.11.1 by the 7.11.2 patch; now aligned (7.12.0).
