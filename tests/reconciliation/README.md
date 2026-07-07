# Reconciliation Tests

Layer-to-layer count and value reconciliation tests.

## Active Tests

| Test | Validates |
|------|-----------|
| `assert_raw_silver_ticket_count_match` | int_pos_tickets count within 1% of raw gateway tickets (with sold_at) |
| `assert_silver_gold_revenue_reconciliation` | fct_daily_operations ticket_revenue within 0.1% of int_pos_tickets total |

## Disabled Tests — in `disabled/` subfolder

| Test | Blocked By |
|------|-----------|
| `assert_raw_silver_retail_count_match` | int_pos_retail (doesn't exist yet — no Shopify) |
| `assert_silver_gold_visitor_reconciliation` | Logic needs rework (ticket count ≠ gate scan count) |
