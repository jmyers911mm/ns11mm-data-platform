# Business Rules Tests

Domain invariants and business logic validation tests.

**Naming convention:** `assert_*` tests run at `severity: error` (a failure blocks
the build); `alert_*` tests run at `severity: warn` — monitoring-style checks that
surface issues without breaking the daily build.

## Active Tests (7)

| Test | Severity | Validates |
|------|----------|-----------|
| `alert_null_primary_keys_in_raw` | warn | Raw gateway seed tables carry no null primary keys (CSV-load guard) |
| `assert_critical_tables_not_empty` | error | 15 critical fact / feature / intermediate tables have >0 rows after a build |
| `assert_date_coverage` | error | dim_date covers 2000-01-01 through 2035-12-31 |
| `assert_no_future_tickets` | error | No tickets with implausible future sold_at or ticket_date |
| `assert_no_negative_attendance` | error | No negative attendance counts in fct_daily_performance |
| `assert_no_negative_retail_revenue` | error | No negative net_sales / net_profit in fct_retail_performance and fct_retail_daily |
| `assert_no_negative_revenue` | error | No negative `ticket_revenue` in fct_daily_operations |

## Disabled Tests — in `disabled/` subfolder

| Test | Blocked By |
|------|-----------|
| `assert_campaign_rates_in_bounds` | fct_campaign_performance (disabled) |
| `assert_no_future_transactions` | fct_ticket_sales (disabled) |
