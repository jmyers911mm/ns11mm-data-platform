# Business Rules Tests

Domain invariants and business logic validation tests.

## Active Tests

| Test | Validates |
|------|-----------|
| `assert_date_coverage` | dim_date covers 2000-01-01 through 2035-12-31 |
| `assert_no_negative_revenue` | No negative `ticket_revenue` in fct_daily_operations |
| `assert_no_future_tickets` | No tickets with implausible future sold_at or ticket_date |
| `assert_critical_tables_not_empty` | 6 critical tables have >0 rows after build |

## Disabled Tests — in `disabled/` subfolder

| Test | Blocked By |
|------|-----------|
| `assert_campaign_rates_in_bounds` | fct_campaign_performance (disabled) |
| `assert_no_future_transactions` | fct_ticket_sales (disabled) |
