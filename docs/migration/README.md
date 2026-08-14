# Legacy Pentaho Reference Capture

The Pentaho server (`pentahoreportingdb`, MySQL `911dw`) is scheduled to lapse
**5 January 2027**. Everything in this directory is a machine-readable copy of logic that
exists nowhere else once that happens. It is reference material, not code: nothing here is
executed by dbt, and nothing here is on the DAG.

Committed by release **8.0.0**, ahead of the rest of the v8 correction series, because the
deadline is external and unmovable while the rest of v8 is not.

## Why this exists

The v8 series corrects roughly two dozen places where the platform diverges from the legacy
estate. Every one of those corrections was found by reading legacy SQL. After January the
legacy SQL is gone, and any correction we have not yet made becomes unverifiable — we would
be left with a number that disagrees with a report nobody can re-read.

`RECOVERY_CHECKLIST.md` in this directory is the more urgent half: it lists logic that is
already missing from this capture and has to be pulled off the server by hand.

## What is here

| Path | Contents |
|---|---|
| `legacy_sql/` | 216 `.sql` files, one per Pentaho transformation. Every `TableInput` SQL block, with header comments naming the transformation's write targets, table lookups, Excel sinks and `.prpt` outputs. |
| `legacy_report_sql/` | 309 report queries extracted from the nine live `.prpt` bundles. **This is the half that is easiest to lose** — these queries live only inside binary report archives on the server, and the transformation graph does not show them. |
| `index/pentaho_parsed.json` | All 216 transformations and 80 jobs as structured JSON: connections, step types, SQL blocks, write targets, mail entries, Excel and PRPT sinks. |
| `index/closure2.json` | The live/dead classification. Which of the 216 transformations are upstream of the 17 live reports (134), which are not (82), and the source-table closure per connection. |
| `index/prpt_tables.json` | Table references per live report, extracted from the `.prpt` queries. |
| `index/parse2.py`, `index/closure2.py` | The extractors. Re-runnable against a fresh export of the Pentaho repository if one is taken before decommission. |

## How this was built

`parse2.py` walks `Pentaho/Transformations/*.ktr` and `Pentaho/Jobs/*.kjb` as XML. `.prpt`
files are zip archives; the report SQL sits in `datasources/sql-ds.xml` under
`data:query` / `data:static-query` elements, HTML-escaped. `closure2.py` walks backwards from
the 17 live reports through every `911dw` table to the source systems, seeding from both the
transformation graph and the `.prpt` table references — seeding from the transformation graph
alone misses `fact_all_donations`, `fact_passes_by_hour`, `fact_visitors_hourly`,
`fact_dsr_forecasts` and `fact_profit_from_retail`, all of which are read directly by report
queries.

## How to use it

Grep it. That is the point of the flat `.sql` layout — the exclusion lists, PLU cohorts,
cutover dates and facility mappings that the v8 releases encode as seeds were all found this
way.

```
# every place a PLU cohort is excluded
grep -rn "plu not in" legacy_sql/

# what writes a given 911dw table
grep -rln "WRITES: .*fact_retail_analysis" legacy_sql/

# how a live report actually queries a table
grep -n "fact_dpr_report_data" legacy_report_sql/new_dpr.sql
```

Header comments in `legacy_sql/*.sql` carry `-- WRITES:`, `-- LOOKUP:`, `-- EXCEL OUT:` and
`-- PRPT:` lines, so the lineage of any file is readable from its first twenty lines.

## The 17 live reports this capture is scoped around

Daily Performance Report - New · DPR - MTD · DPR - YTD · DPR Excel Data · Memorial Museum
Daily Tracker - YTD · Retail Performance Report · Retail Carts Analysis Report · Today's Sales
Report · Daily Scan Report · Attendance Report · Daily Attendance Report · Website Commerce
Report · Blue State WiFi Email List Export · Monthly Retail KPI · Earned Income Variance
Report · Donations Analysis Report · Retail Analysis Report

The 82 transformations classified dead in `closure2.json` are retained in `legacy_sql/`
anyway. They cost nothing to keep and the classification is an inference — if a report we
believe retired turns out to still be running, its logic is still here.

## Caveats on the capture

- **Job scheduling is not in it.** Cron expressions live in the Pentaho server's own
  scheduler, not in the `.kjb` files. Cadences have to be read off the server.
- **`SSH` and `Rest` steps are opaque.** Six steps (the Sensource API chain) invoke remote
  scripts whose logic is not in the repository at all.
- **`InsertUpdate` field maps are only partly captured.** The parser records the target table
  and key columns; the full source-field → target-column mapping is in the `.ktr` XML but not
  flattened into `legacy_sql/`. Where a v8 release depends on an inferred column mapping it
  says so, and `RECOVERY_CHECKLIST.md` lists the ones that need confirming.
- **Connection credentials are excluded** by construction — `parse2.py` captures connection
  *names* only. No `.prpt` password blobs are committed; the `data:property name="password"`
  values in the source bundles were not carried into `legacy_report_sql/`.
