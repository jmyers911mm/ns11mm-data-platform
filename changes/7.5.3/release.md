# 7.5.3: Resource Monitor Fix & Portable Semantic View DDL

- **Date:** 2026-07-31
- **Version:** 7.5.3

Session date: 2026-07-31. Production dbt run was blocked because `DBT_DEV_MONITOR` exceeded its
5-credit monthly quota (used 5.04). Restored the warehouse, audited test and alert coverage
across all mart tables and semantic views, and fixed the semantic view DDL generator to stop
hardcoding a database name.

## Fixed

| Issue | Resolution |
|-------|------------|
| `DBT_DEV_MONITOR` quota exhausted (5.04 / 5.00 credits), suspending `DBT_DEV_WH` | Increased monthly quota from 5 → 10 credits; warehouse resumed |
| `deploy_semantic_view_*.sql` hardcoded `NS11MM_DW_DEV` database | Scripts now emit schema-qualified names only; resolve from session database |

## Changed

- **`scripts/generate_semantic_view_ddl.py`** — Default behaviour omits the database qualifier
  from all DDL object references (view name, table FQNs). Scripts resolve against the current
  session database (`USE DATABASE <target>`). Pass `--database <name>` to pin a specific
  database when needed (e.g. `--database NS11MM_DW_PROD` for production deploys).
- **4 regenerated DDL files** — `deploy_semantic_view_{attendance,dpr,retail,unified}.sql` now
  use `MARTS.*` / `SEEDS.*` instead of `NS11MM_DW_DEV.MARTS.*` / `NS11MM_DW_DEV.SEEDS.*`.

## Audit Findings (informational, not yet remediated)

- All 5 Snowflake alerts in `NS11MM_DW_DEV.MONITORING` are **SUSPENDED** (source freshness,
  dbt failures, credit consumption, long-running queries, warehouse utilization).
- `assert_critical_tables_not_empty` covers only 6 of 17 enabled models — newer facts
  (`fct_daily_performance`, `fct_retail_daily`, `fct_retail_performance`, `fct_daily_scan`,
  `fct_today_sales_hourly`, budget facts, `ml_visitor_forecast_training`) are missing.
- No revenue reconciliation test for the retail path (silver → gold).
- No resource-monitor-approaching-limit alert exists.

## Migration notes

- **No breaking changes** to model SQL or schema.
- Semantic view deploy scripts now require the session database to be set before execution
  (e.g. `USE DATABASE NS11MM_DW_DEV_JMYERS;`) unless `--database` is passed at generation time.

---
