{{ config(enabled=false) }}
-- Validates that Gold revenue totals reconcile with Silver source within 0.1%
-- STATUS: Awaiting production models
/*
with int_revenue as (
    select sum(transaction_amount) as total
    from {{ ref('int_pos_tickets') }}
    where transaction_date >= '2024-01-01'
),
gold_revenue as (
    select sum(ticket_revenue) as total
    from {{ ref('fct_daily_operations') }}
    where visit_date >= '2024-01-01'
),
check as (
    select abs(s.total - g.total) / nullif(s.total, 0) as diff_pct
    from int_revenue s, gold_revenue g
)
select diff_pct from check where diff_pct > 0.001
*/
select 1 where 1 = 0
