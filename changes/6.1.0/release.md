# 6.1.0: Resource Monitor Fix & Test/Alert Coverage Audit

- **Date:** 2026-07-29
- **Version:** 6.1.0

Session date: 2026-07-29. dbt execution failed because warehouse `DBT_DEV_WH` was suspended by
resource monitor `DBT_DEV_MONITOR` (5-credit monthly quota exceeded by 0.04 credits). Diagnosed
root cause, restored the warehouse, and audited test + alert coverage across all mart tables and
semantic views.

## Fixed

| Issue | Resolution |
|-------|------------|
| `DBT_DEV_MONITOR` quota exhausted (5.04 / 5.00 credits) | Increased monthly quota from 5 → 10 credits |
| `DBT_DEV_WH` suspended, blocking all 104 dbt models | Resumed warehouse after quota increase |

## Audit Findings — Test Coverage

| Finding | Status | Detail |
|---------|--------|--------|
| Schema-level column tests (PK unique/not_null, FK relationships) | ✅ Covered | All 13 dimensions + 11 facts + 2 ML features have schema tests |
| `assert_critical_tables_not_empty` | ⚠️ Partial | Only covers 6 of 17 enabled tables/views. Missing: `fct_daily_performance`, `fct_retail_daily`, `fct_retail_performance`, `fct_daily_scan`, `fct_today_sales_hourly`, `fct_budget_admissions_forecasts`, `fct_budget_dpr_forecasts`, `fct_budget_retail_forecasts`, `ml_visitor_forecast_training` |
| Revenue reconciliation (silver → gold) | ⚠️ Partial | Only ticket revenue (`int_pos_tickets` → `fct_daily_operations`). No retail reconciliation (`int_retail__performance` → `fct_retail_performance`) |
| Negative-value assertions | ⚠️ Partial | Only `fct_daily_operations.ticket_revenue`. No coverage for retail net_sales/net_profit or attendance counts |
| Grain uniqueness (singular tests) | ✅ Covered | Multi-column grain tests exist in schema.yml for all composite-key facts |

## Audit Findings — Alerts

| Alert | State | Issue |
|-------|-------|-------|
| `ALERT_SOURCE_FRESHNESS` | **SUSPENDED** | No freshness notifications firing |
| `ALERT_DBT_RUN_FAILURES` | **SUSPENDED** | Today's failure went unnoticed |
| `ALERT_CREDIT_CONSUMPTION` | **SUSPENDED** | Quota breach was silent |
| `ALERT_LONG_RUNNING_QUERIES` | **SUSPENDED** | No performance monitoring active |
| `ALERT_WAREHOUSE_UTILIZATION` | **SUSPENDED** | No queuing detection active |
| Resource monitor quota alert | **MISSING** | No alert exists for monitor quota approaching limits |

## Audit Findings — Semantic Views

| Semantic View | Backing Tables Tested | Notes |
|---------------|----------------------|-------|
| `DPR` | `fct_daily_performance`, `dim_date` | `fct_daily_performance` missing from emptiness test |
| `RETAIL` | `fct_retail_daily`, `fct_retail_performance`, `dim_date` | Both facts missing from emptiness test; no retail revenue reconciliation |
| `UNIFIED` | `fct_daily_performance`, `fct_retail_performance`, `fct_daily_scan`, `dim_date` | `fct_daily_scan` missing from emptiness test |
| `ATTENDANCE` | `fct_daily_scan`, `fct_ticket_demand_forecast`, `fct_ticket_availability` | `fct_daily_scan` missing from emptiness test |
| `FUNDRAISING_ECOM` | `dim_customer`, `dim_campaign`, `dim_payment_method`, `dim_fund` | Stub dimensions — tests pass trivially |

## Recommended Next Steps (not yet implemented)

1. Resume all 5 suspended alerts
2. Add resource monitor quota alert (notify at 75%, alert email at 90%)
3. Expand `assert_critical_tables_not_empty` to cover all mart facts backing semantic views
4. Add retail revenue reconciliation test (`int_retail__performance` → `fct_retail_performance`)
5. Add negative-value assertions for `fct_retail_daily.net_sales` and `fct_daily_scan` attendance

## Migration notes

- **No breaking changes.** Only the resource monitor quota was altered (5 → 10 credits/month).
- All alerts remain suspended pending deliberate re-enablement.

---
