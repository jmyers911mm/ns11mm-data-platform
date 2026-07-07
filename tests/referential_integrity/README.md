# Referential Integrity Tests

FK and seed consistency tests across the Gold layer.

## Active Tests

| Test | Validates |
|------|-----------|
| `assert_gold_daily_ops_no_orphan_dates` | All visit_date values in fct_daily_operations exist in dim_date |

## Disabled Tests — in `disabled/` subfolder

| Test | Blocked By |
|------|-----------|
| `assert_campaign_fk_integrity` | fct_campaign_performance + dim_campaign (disabled) |
| `assert_customer_segments_match_seed` | dim_customer (disabled) |
| `assert_payment_methods_match_seed` | fct_ticket_sales (disabled) |
| `assert_ticket_types_match_seed` | fct_ticket_sales (disabled) |
