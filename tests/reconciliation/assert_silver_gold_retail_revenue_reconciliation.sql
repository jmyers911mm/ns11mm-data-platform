-- Test (reconciliation): Gold retail net_sales reconciles with silver within 0.1%
-- Co-authored with CoCo
-- Severity: error — drift beyond tolerance means gold lost or double-counted retail revenue

with silver_total as (
    select sum(net_sales) as total
    from {{ ref('int_retail__performance') }}
),

gold_total as (
    select sum(net_sales) as total
    from {{ ref('fct_retail_performance') }}
),

reconciliation as (
    select abs(s.total - g.total) / nullif(s.total, 0) as diff_pct
    from silver_total s, gold_total g
)

select diff_pct
from reconciliation
where diff_pct > 0.001
