{{ config(enabled=false) }}
-- Validates that Gold visitor counts reconcile with Silver source
-- STATUS: Awaiting production models
/*
with silver_visitors as (
    select count(distinct ticket_id) as total
    from {{ ref('silver_pos_tickets') }}
    where transaction_date >= '2024-01-01'
),
gold_visitors as (
    select sum(total_visitors) as total
    from {{ ref('fct_daily_operations') }}
    where visit_date >= '2024-01-01'
),
check as (
    select abs(s.total - g.total) / nullif(s.total, 0) as diff_pct
    from silver_visitors s, gold_visitors g
)
select diff_pct from check where diff_pct > 0.01
*/
select 1 where 1 = 0
