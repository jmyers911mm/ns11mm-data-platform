# 7.11.1: Patch: DPR Semantic View Deploy Failure

- **Date:** 2026-07-31
- **Version:** 7.11.1

`CREATE SEMANTIC VIEW` for DPR failed with "Invalid metric definition for
'DP.AVG_TICKET_PRICE': A metric must directly refer to another aggregate-level
expression ... without an aggregate." Root cause: in 7.8.0 the ratio was authored as
`SUM(TOTAL_ADMISSION_REVENUE) / NULLIF(SUM(TICKETS_SOLD), 0)`, but
`TOTAL_ADMISSION_REVENUE` is BOTH a fct column and a metric name in the DPR view — and
inside metric expressions Snowflake resolves the name to the METRIC, producing an
aggregate-of-an-aggregate.

## Fixed (DPR.sv.yaml + regenerated deploy_semantic_view_dpr.sql)

- New fact **`ADMISSION_REVENUE_VALUE`** — row-grain alias of the governed
  `TOTAL_ADMISSION_REVENUE` column, so the same-named metric can sum it unambiguously:
  `TOTAL_ADMISSION_REVENUE AS SUM(ADMISSION_REVENUE_VALUE)`. Still the
  defined-once column; still never re-derived from components.
- **`AVG_TICKET_PRICE`** authored metric-over-metric (Snowflake's required form for
  ratios): `TOTAL_ADMISSION_REVENUE / NULLIF(TOTAL_TICKETS_SOLD, 0)` — mathematically
  identical to the locked ratio-of-sums, recomputed at query grain.
- **`MUS_STORE_PROFIT_PER_VISITOR`** same form:
  `TOTAL_MUS_STORE_GROSS_PROFIT / NULLIF(TOTAL_MUSEUM_ATTENDANCE, 0)`.
  (UNIFIED's SUM-of-columns form stays as-is — its metric names don't collide with
  column names, so it deploys; both forms are the same ratio-of-sums.)
- `--check` green; 49 metrics.

## Migration notes

Re-run `scripts/deploy_semantic_view_dpr.sql` (after `USE DATABASE <target>`) in every
database you deploy to. No dbt model changes.

---
