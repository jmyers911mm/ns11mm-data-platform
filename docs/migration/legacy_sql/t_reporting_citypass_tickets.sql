-- TRANSFORMATION: t_reporting_citypass_tickets
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: CityPASS Booklet revenue [TableInput] conn=911DW =====
select key_date,0 as citypass_tickets, sum(amount) as citypass_revenue
from fact_museum_citypass_booklets f inner join dim_galaxy_items g on f.key_museum_category =g.key_category
inner join dim_date d on f.key_date=d.date_key
where 
g.plu in ('MUSGADADCP005', 'MUSGADYSCP005')
and d.date_value >= '20160601'
group by key_date

-- ===== STEP: ti: Get CityPASS Tickets before scan change [TableInput] conn=911DW =====
select key_date, ifnull(sum(quantity),0) as citypass_tickets, sum(amount) as citypass_revenue
from fact_museum_citypass f inner join dim_galaxy_items g on f.key_museum_category= g.key_category
inner join dim_date d on f.key_date = d.date_key
where  
(g.account_idno like '%CPA%' or g.account_idno like '%CPB%')
and d.date_value >= '20140521'
and d.date_value < '20160630'
group by key_date

-- ===== STEP: ti: Get CityPASS Tickets post scan change [TableInput] conn=911DW =====
select key_date, ifnull(sum(quantity),0) as citypass_tickets, sum(quantity*amount) as citypass_revenue
from fact_museum_citypass_scanchange f inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20160601'
and f.key_coupon_category in ('Adult','Youth')
group by key_date