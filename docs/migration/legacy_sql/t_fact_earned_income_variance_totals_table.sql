-- TRANSFORMATION: t_fact_earned_income_variance_totals_table
-- DESC: 

-- WRITES: 911DW:.earned_income_report_analysis (InsertUpdate)


-- ===== STEP: Table input 2 [TableInput] conn=911DW =====
select key_date, sum(total_admissions_revenue), sum(total_tickets_sold), sum(forecasted_total_tickets), sum(forecasted_total_admissions), (sum(total_tickets_sold)- sum(forecasted_total_tickets)) as total_tickets_diff,
(sum(total_admissions_revenue) - sum(forecasted_total_admissions)) as total_revenue_diff
from
(select e.key_date as key_date, sum(actual_revenue + citypass_revenue + service_fees) as total_admissions_revenue, 0 as total_tickets_sold, 0 as forecasted_total_tickets,
0 as forecasted_total_admissions 
  from earned_income_report_analysis e, dim_date d
where e.key_date = d.date_key
and d.date_value >= '20140521'
group by e.key_date
union
select e.key_date as key_date, 0 as total_admissions_revenue, sum(total_tickets) as total_tickets_sold, 0 as forecasted_total_tickets,
0 as forecasted_total_admissions 
  from earned_revenue_report_values e, dim_date d
where e.key_date = d.date_key
and d.date_value >= '20140521'
group by e.key_date
union
select f.key_date as key_date, 0 as total_admissions_revenue, 0 as total_tickets_sold, sum(f.tickets_sold + citypass_tickets) as forecasted_total_tickets,
0 as forecasted_total_admissions 
from fact_forecasted_value_for_date f, dim_date d
where f.key_date=d.date_key
and d.date_value>= '20140521'
group by f.key_date
union
select f.key_date as key_date,0 as total_admissions_revenue, 0 as total_tickets_sold, 0 as forecasted_total_tickets, 
sum(f.revenue + citypass_revenue + service_fees) as forecasted_total_admissions
from fact_forecasted_value_for_date f, dim_date d
where f.key_date=d.date_key
and d.date_value >= '20140521'
group by f.key_date) as A
where key_date < ?
group by key_date