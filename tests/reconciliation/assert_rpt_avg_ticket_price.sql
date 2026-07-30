-- Test (reconciliation): rpt avg_ticket_price = revenue / tickets_sold from the fact (day grain)
-- Severity: error — fails if the report formula diverges from the governed fact (define-once)
with fact as (
    select date_key, total_admission_revenue, tickets_sold
    from {{ ref('fct_daily_performance') }}
    where tickets_sold > 0
),
report as (
    select date_key, avg_ticket_price
    from {{ ref('rpt_daily_performance_report') }}
)
select r.date_key
from report r
inner join fact f on r.date_key = f.date_key
where abs(r.avg_ticket_price - (f.total_admission_revenue / f.tickets_sold)) > 0.01