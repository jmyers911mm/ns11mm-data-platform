-- Test (reconciliation): Gold revenue totals reconcile with the intermediate source within 0.1%
-- Severity: error — drift beyond tolerance means a gold aggregation lost or double-counted revenue

with int_revenue as (
    select sum(total_amount) as total
    from {{ ref('int_pos_tickets') }}
),

gold_revenue as (
    select sum(ticket_revenue) as total
    from {{ ref('fct_daily_operations') }}
),

reconciliation as (
    select abs(s.total - g.total) / nullif(s.total, 0) as diff_pct
    from int_revenue s, gold_revenue g
)

select diff_pct
from reconciliation
where diff_pct > 0.001
