-- TRANSFORMATION: t_fact_earned_income_variance_avg_ticket
-- DESC: 

-- WRITES: 911DW:.earned_income_report_analysis (InsertUpdate)


-- ===== STEP: Table input 2 [TableInput] conn=911DW =====
select key_date, sum(avg_ticket_price), sum(forecasted_avg_ticket_price), (sum(avg_ticket_price) - sum(forecasted_avg_ticket_price)) as avg_ticket_price_diff
from
(select e.key_date as key_date, sum(actual_revenue) / sum(actual_tickets) as avg_ticket_price, 0 as forecasted_avg_ticket_price
from earned_income_report_analysis e, dim_date d
where e.key_date = d.date_key
and d.date_value >= '20140521'
group by e.key_date
union
select f.key_date as key_date,0 as avg_ticket_price, sum(f.revenue) / sum(f.tickets_sold) as forecasted_avg_ticket_price 
from fact_forecasted_value_for_date f, dim_date d
where f.key_date=d.date_key
and d.date_value >= '20140521'
group by f.key_date) as A
where key_date < ?
group by key_date