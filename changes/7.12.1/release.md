# 7.12.1: Tracker DirectQuery Support (week bucket in-platform, composite DRY, card view)

- **Date:** 2026-08-07
- **Version:** 7.12.1

Jeremy chose DirectQuery for the Tracker PBIX (no separate refresh schedule to race the
nightly load). DQ forbids the calculated-column / text-measure patterns the Import build
used, so the logic moves into the platform — where ADR-004 wanted it anyway.

## Added

- **dim_date**: `week_start_monday` / `week_end_sunday` — static Mon-Sun week bounds for
  Mon-anchored report weeks (the existing first/last_day_of_week are Sun-anchored).
- **rpt_tracker_week_bucket** (view, POWERBI_ROLE): one row per date_key with the Daily
  Tracker's rolling buckets — 'Prior Years' / '1/1 - MM/DD' / current + two prior Mon-Sun
  weeks / 'Future' — plus a `bucket_sort` date. Anchor = yesterday America/New_York,
  computed at query time (always current under DQ, immune to a delayed dim_date rebuild).
  Replaces the Power BI calculated columns.
- **rpt_tracker_narrative_card** (view): the deterministic ASCII analyst card rendered in
  SQL over rpt_tracker_narrative_brief — binds as a plain view under DQ, replacing the
  Value.NativeQuery M pattern for this report.

## Changed

- **Earned-revenue composite defined once** (prime rule): `total_earned_revenue` is now a
  column on `rpt_tracker_powerbi`, `earned_revenue_projection` on
  `rpt_tracker_budget_daily`; `rpt_tracker_report_long` and `rpt_tracker_narrative_brief`
  consume the columns instead of re-authoring the sums. Fixes a latent divergence: the
  report_long's actual-side composite summed WITHOUT coalesce (any NULL component NULLed
  the whole line) while the brief coalesced — the coalesced form is now canonical.
  Output-equivalent otherwise; verify with a day-grain row-count + total diff on
  rpt_tracker_report_long before/after.

## Notes

- Memorial-vs-Museum revenue split is deliberately NOT added (ADR-005 gate — committee
  rule pending). The provisional split stays in DAX, clearly labeled.
- Power BI: remove the Week Bucket / Bucket Start calculated columns; bind
  rpt_tracker_week_bucket (relate date_key -> both tracker facts' report_date), use
  week_bucket on matrix columns sorted by bucket_sort, filter out 'Future'/'Prior Years'.
