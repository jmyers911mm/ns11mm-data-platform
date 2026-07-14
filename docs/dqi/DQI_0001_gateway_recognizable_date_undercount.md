# DQI-001: Gateway ticket revenue undercount from null recognize dates

- **Status:** Resolved
- **Severity:** High
- **Dimension:** Accuracy
- **Domain:** Revenue / Ticketing
- **Detected:** 2026-07-10 — reconciliation test `assert_ticket_revenue_recon` failed
- **Reported:** 2026-07-10
- **Owner:** Jeremy Myers
- **Affected:** stg_gateway__journal, int_revenue__tickets, fct_ticket_revenue, rpt_daily_revenue

> Template incident. Copy this file, rename it `DQI_00NN_short_slug.md`, and fill in the
> fields above and the sections below. The metadata lines (`- **Key:** value`) drive the
> list, badges, and header on the incident-log page; the `##` sections render as the body.

## Summary

Daily ticket revenue was undercounting because the recognize-date basis dropped rows where
`rme.start_at` was null. The result was a large, silent shortfall in reported tickets and
revenue for the affected window.

## Detection

The `assert_ticket_revenue_recon` reconciliation test flagged a variance between the DPR
total and the Pentaho baseline. The test compares daily `tickets_sold` against the legacy
control total and fails when the delta exceeds the tolerance threshold.

## Impact

Reported `tickets_sold` showed 8,267 units against an expected 105,781 for the window — an
undercount of roughly 92 percent. Any report or Cortex query sourced from
`rpt_daily_revenue` inherited the shortfall until the fix shipped.

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