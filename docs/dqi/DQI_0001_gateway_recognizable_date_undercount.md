# DQI-001: Gateway ticket revenue undercount from null recognize dates

- **Status:** Resolved
- **Severity:** High
- **Dimension:** Accuracy
- **Domain:** Revenue / Ticketing
- **Detected:** 2026-07-10 — reconciliation test `assert_silver_gold_revenue_reconciliation` failed
- **Reported:** 2026-07-10
- **Owner:** Jeremy Myers
- **Affected:** stg_gateway__jnltickets, stg_gateway__jnldetails, int_gateway__ticket_journal_lines, fct_daily_performance, rpt_daily_performance_report

## Summary

Daily ticket revenue was undercounting because the recognize-date basis dropped rows where
`rme.start_at` was null. The result was a large, silent shortfall in reported tickets and
revenue for the affected window.

## Detection

The `assert_silver_gold_revenue_reconciliation` reconciliation test flagged a variance between the DPR
total and the Pentaho baseline. The test compares daily `tickets_sold` against the legacy
control total and fails when the delta exceeds the tolerance threshold.

## Impact

Reported `tickets_sold` showed 8,267 units against an expected 105,781 for the window — an
undercount of roughly 92 percent. Any report or Cortex query sourced from
`rpt_daily_performance_report` inherited the shortfall until the fix shipped.

## Root Cause

The `gateway_recognized_date` macro used `rme.start_at` directly, with no fallback. A
significant volume of rows have a null `start_at`, so those rows were assigned a null
recognize date and dropped from the daily aggregation.

## Resolution

Applied a coalesce fallback in the `gateway_recognized_date` macro (recognize basis-182):
`coalesce(rme.start_at, <fallback>)`. Rebuilt the affected models and re-ran the
reconciliation test, which passed. Recovered the full 105,781 units for the window.

## Follow-up

- Added a `not_null` test on the coalesced recognize date so a future regression fails fast.
- Backfilled the affected historical partitions.
- Logged the macro change in the platform changelog.