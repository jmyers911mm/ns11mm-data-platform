-- rpt.avg_ticket_price must equal total_admission_revenue / tickets_sold from the
-- governed fact, at day grain. Fails if the report's formula ever diverges.
with fact as (
    select date_id, total_admission_revenue, tickets_sold
    from {{ ref('fct_daily_performance') }}
    where tickets_sold > 0
),
report as (
    select date_id, avg_ticket_price
    from {{ ref('rpt_daily_performance_report') }}
)
select r.date_id
from report r
inner join fact f on r.date_id = f.date_id
where abs(r.avg_ticket_price - (f.total_admission_revenue / f.tickets_sold)) > 0.01