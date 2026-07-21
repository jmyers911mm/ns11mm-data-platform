-- Reconciliation test: rpt avg_ticket_price must equal revenue / tickets_sold from fact
-- Co-authored with CoCo
-- Fails if the report's formula ever diverges from the governed fact at day grain.
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