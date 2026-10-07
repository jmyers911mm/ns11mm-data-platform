# 7.13.0: ADR-021: Report Serving Layer (role grammar + family directories)

- **Date:** 2026-08-10
- **Version:** 7.13.0

Structural release. No metric or report output changes — every model's SQL is byte-identical
except the two housekeeping deletions below. What changes is where files live and what governs
them.

## Added

- **ADR-021 — "Report Serving Models Are Named by Role, and Projection Chains Off a Wrapper
  Are Permitted."** Codifies the seven serving roles that emerged across 7.12.0–7.12.5
  (`*_powerbi`, `*_budget_daily`/`*_conform`, `*_period_windows`, serving shapes, presentation
  shapes, `*_narrative_brief`, `*_narrative`/`*_narrative_card`), the legal read direction
  through the chain, the ratio rule, the composite rule, and the typed-NULL placeholder
  convention. Also records that presentation formatting in dbt is intentional under
  DirectQuery rather than ADR-004 drift.

## Changed

- **ADR-018's 2026-07-29 amendment is superseded by ADR-021.** That amendment carved out the
  rpt-from-rpt prohibition by enumerating six filenames; the chains have since grown to roughly
  twenty models across seven families, so every newer model header was citing a sanction the
  governance doc did not actually grant. ADR-021 replaces the enumeration with a role-based rule
  that covers future reports without amendment. The original amendment text is retained in
  ADR-018 for the record.
- **`models/marts/reports/` reorganised into one directory per report family** — dpr, retail,
  tracker, attendance, scan, today_sales, website_commerce, restricted (plus the existing
  disabled/). 70 files moved. `ref()` is name-based so no reference changed; `dbt_project.yml`
  configs cascade into subdirectories so no config changed.
- **The 997-line `models/marts/reports/schema.yml` is split into eight per-family files**
  (25–379 lines each). The parent file is removed, since no report model was left unowned.
- **Report-layout dimensions co-located with their reports** — the eight `dim_*_line_item` /
  `dim_*_print_line` models move from `models/marts/dimensions/` into their family directory.
  Their `materialized='table'` is set in each model's own config, so materialization is
  unchanged; their dbt group moves from `gold_dimensions` to `gold_reports` (all are
  `access: public`, so nothing breaks). Business dimensions stay in `dimensions/`, whose
  schema.yml drops from 326 to 236 lines.
- **Report-layout seeds moved to `seeds/report_layout/`** (the five `*_line_items` and two
  `*_print_lines`). Seed paths do not affect `ref()`.

## Removed

- **`rpt_tracker_week_bucket.sql`** — superseded by the `dim_date` columns in 7.12.2, whose
  APPLY.sh deletion never ran. Also `DROP VIEW IF EXISTS MARTS.RPT_TRACKER_WEEK_BUCKET;` in
  Snowflake.

## Verified

- `dbt parse` green: 132 enabled models + 7 gated (`enabled=false`), 394 data tests, 25 seeds.
- File/model integrity checked both directions: every `.sql` outside `disabled/` is either
  registered or explicitly `enabled=false`, and every registered model resolves to a file. No
  model was lost or orphaned by the move.

## Open items carried forward

- ADR-021 §3 needs Data & AI Committee ratification; until then model headers cite it as
  Proposed. Twenty models depend on it — the same exposure the 2026-07-29 amendment carried,
  now written down accurately.
- `TOTAL_ESTIMATED_REVENUE` is authored twice (`rpt_dpr_mtd_ytd_long` and inline in
  `rpt_dpr_report_long`), which violates ADR-021's composite rule on the day it is written.
  Recorded as an accepted risk in the ADR with remediation owed next release.
- Three composites live in a serving model rather than the semantic view
  (`TOTAL_GUIDED_TOUR_REVENUE`, `TOTAL_OTHER_VISITOR_REVENUE`, `TOTAL_ESTIMATED_REVENUE`);
  promote to sv metrics.
