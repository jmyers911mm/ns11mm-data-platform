# Reconciliation Tests

Layer-to-layer count and value reconciliation tests.

## Active Tests (4)

| Test | Validates |
|------|-----------|
| `assert_raw_silver_ticket_count_match` | int_pos_tickets count within 1% of deduped staging tickets (with sold_at) |
| `assert_rpt_avg_ticket_price` | rpt avg_ticket_price = revenue / tickets_sold from fct_daily_performance at day grain (define-once check) |
| `assert_silver_gold_retail_revenue_reconciliation` | Gold retail net_sales reconciles with int_retail__performance within 0.1% |
| `assert_silver_gold_revenue_reconciliation` | fct_daily_operations ticket_revenue within 0.1% of int_pos_tickets total |

## Disabled Tests — in `disabled/` subfolder

| Test | Blocked By |
|------|-----------|
| `assert_raw_silver_retail_count_match` | int_pos_retail (doesn't exist yet — no Shopify) |
| `assert_silver_gold_visitor_reconciliation` | Logic needs rework (ticket count ≠ gate scan count) |
