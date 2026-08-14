-- TRANSFORMATION: t_fact_citypass_c3_earned_income_variance
-- DESC: 

-- WRITES: 911DW:.earned_income_report_analysis (InsertUpdate)
-- WRITES: 911DW:.earned_income_report_analysis (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=911DW =====
select key_date, sum(citypass_tickets + citypass_scanchange) as citypass_tickets, sum(forecasted_citypass_tickets) as forecasted_citypass_tickets, ((sum(citypass_tickets)+ sum(citypass_scanchange)) - sum(forecasted_citypass_tickets) )as diff
from
(select f.key_date as key_date, sum(quantity) as citypass_tickets,0 as citypass_scanchange, 0 as forecasted_citypass_tickets
 from fact_museum_citypass f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and (g.account_idno like '%CPA%' or g.account_idno like '%CPB%')
and d.date_value >= '20150201'
group by f.key_date
union
select d.date_key as key_date, 0 as citypass_tickets, sum(quantity) as citypass_scanchange, 0 as forecasted_citypass_tickets
from fact_museum_citypass_scanchange f, dim_date d
where f.key_date= d.date_key
and d.date_value >= '20160601'
and f.key_coupon_category in ('Adult','Youth')
group by d.date_key
union
select f.key_date, 0 as citypass_tickets, 0 as citypass_scanchange,sum(f.citypass_tickets) as forecasted_citypass_tickets 
from
fact_forecasted_value_for_date f, dim_date d
where f.key_date=d.date_key
and d.date_value >= '20150201'
group by f.key_date
) A
where key_date < ?
group by key_date

-- ===== STEP: Table input 2 [TableInput] conn=911DW =====
select key_date, sum(citypass_ticket_rev + citypass_scanchange_rev + citypass_booklet_rev) as citypass_revenue, sum(forecasted_citypass_ticket_rev) as forecasted_citypass_revenue, 
((sum(citypass_ticket_rev) + sum(citypass_scanchange_rev) + sum(citypass_booklet_rev)) - sum(forecasted_citypass_ticket_rev) )as diff
from
(select f.key_date as key_date, sum(amount) as citypass_ticket_rev, 0 as citypass_scanchange_rev,0 as forecasted_citypass_ticket_rev, 0 as citypass_booklet_rev
 from fact_museum_citypass f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and (f.key_coupon_category='None')
and (g.account_idno like '%CPA%' or g.account_idno like '%CPB%')
and d.date_value >= '20150201'
group by f.key_date
union
select f.key_date as key_date, sum(quantity*amount) as citypass_ticket_rev, 0 as citypass_scanchange_rev, 0 as forecasted_citypass_ticket_rev, 0 as citypass_booklet_rev
 from fact_museum_citypass f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and (f.key_coupon_category in ('Adult','Youth'))
and (g.account_idno like '%CPA%' or g.account_idno like '%CPB%')
and d.date_value >= '20150201'
group by f.key_date
union
select f.key_date as key_date , 0 as citypass_ticket_rev, sum(quantity*amount) as citypass_scanchange_rev, 0 as forecasted_citypass_ticket_rev, 0 as citypass_booklet_rev
from fact_museum_citypass_scanchange f, dim_date d
where f.key_date = d.date_key
and d.date_value >= '20160601'
and f.key_coupon_category in ('Adult','Youth')
group by d.date_key
union
select f.key_date as key_date , 0 as citypass_ticket_rev, 0 as citypass_scanchange_rev, 0 as forecasted_citypass_ticket_rev, sum(amount) as citypass_booklet_rev
 from fact_museum_citypass_booklets f, dim_galaxy_items g, dim_date d
where f.key_date=d.date_key
and f.key_museum_category =g.key_category
and g.plu in ('MUSGADADCP005', 'MUSGADYSCP005')
and d.date_value >= '20160601'
group by f.key_date
union
select f.key_date as key_date, 0 as citypass_ticket_rev, 0 as citypass_scanchange_rev, sum(f.citypass_revenue) as forecasted_citypass_ticket_rev , 0 as citypass_booklet_rev
from
fact_forecasted_value_for_date f, dim_date d
where f.key_date=d.date_key
and d.date_value >= '20150201'
group by f.key_date
) A
where key_date < ?
group by key_date