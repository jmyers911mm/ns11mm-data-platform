# 7.12.2: Week Buckets Fold into dim_date

- **Date:** 2026-08-07
- **Version:** 7.12.2

Jeremy's call after DirectQuery relationship-folding trouble with the separate
rpt_tracker_week_bucket view: the bucket columns move INTO dim_date, so the Tracker
matrix needs no second date-grain table and no extra relationships.

## Changed

- **dim_date** gains `week_bucket` + `bucket_sort` (Daily Tracker rolling buckets:
  'Prior Years' / '1/1 - MM/DD' / current + two prior Mon-Sun weeks / 'Future').
  Anchored to yesterday America/New_York at BUILD time — same convention as the existing
  ptd comparison flags, and same nightly cadence as the tracker facts, so buckets and
  data roll together. (Trade-off vs the removed view: the view anchored at query time;
  in-dim anchoring is build-time. Accepted — a delayed build delays facts and buckets
  equally.)
- Schema docs added for `week_start_monday` / `week_end_sunday` / `week_bucket` /
  `bucket_sort`.

## Removed

- **rpt_tracker_week_bucket** (model + schema entry) — superseded one release later by
  the dim_date columns. Drop the deployed view: `DROP VIEW IF EXISTS
  MARTS.RPT_TRACKER_WEEK_BUCKET;` (APPLY.sh prints the reminder).

## Power BI

Remove the WeekBucket table from the model; matrix columns = `Dim_Date[WEEK_BUCKET]`
(Sort By -> `Dim_Date[BUCKET_SORT]`), filter out 'Future'/'Prior Years'. No new
relationships — Dim_Date already filters both tracker facts.
