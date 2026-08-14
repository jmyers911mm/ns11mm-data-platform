-- TRANSFORMATION: t_fact_earned_income_variance_revenue_table
-- DESC: 

-- WRITES: 911DW:.earned_income_report_analysis (InsertUpdate)


-- ===== STEP: Table input 2 [TableInput] conn=911DW =====
select key_date, (sum(mus_service_fees)+ sum(mem_service_fees)) as service_fees, sum(forecasted_service_fees),
((sum(mus_service_fees)+ sum(mem_service_fees)) - sum(forecasted_service_fees)) as service_fees_diff, 
 (sum(revenue + c3_revenue+ c3_scanchange_rev +nyp_add_rev + bulk_add_rev)) as actual_revenue, 
sum(forecasted_revenue) as forecasted_revenue, (sum(revenue+ c3_revenue+ c3_scanchange_rev+nyp_add_rev + bulk_add_rev) - sum(forecasted_revenue)) as diff 
from
(select f.key_date, sum(amount) as mus_service_fees, 0 as mem_service_fees, 0 as forecasted_service_fees, 0 as revenue,  0 as forecasted_revenue, 0 as c3_revenue, 0 as c3_scanchange_rev, 0 as nyp_add_rev, 
 0 as bulk_add_rev
from fact_service_fees_new f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and g.account_idno like '%MUF%' and g.account_idno like '%FEE%'
and d.date_value >= '20140521'
group by f.key_date
union
select f.key_date, 0 as mus_service_fees, sum(amount) as mem_service_fees,0 as forecasted_service_fees, 0 as revenue,  0 as forecasted_revenue, 0 as c3_revenue, 0 as c3_scanchange_rev, 0 as nyp_add_rev, 
 0 as bulk_add_rev
from fact_service_fees_new f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and g.account_idno like '%MEF%' and g.account_idno like '%FEE%'
and d.date_value  >= '20140521'
group by f.key_date
union
select f.key_date, 0 as mus_service_fees, 0 as mem_service_fees, sum(f.service_fees) as forecasted_service_fees,0 as revenue,  0 as forecasted_revenue, 0 as c3_revenue, 0 as c3_scanchange_rev, 0 as nyp_add_rev, 
 0 as bulk_add_rev
from fact_forecasted_value_for_date f, dim_date d
where f.key_date=d.date_key
and d.date_value >= '20140521'
group by f.key_date
union
select f.key_date as key_date,0 as mus_service_fees,0 as mem_service_fees,0 as forecasted_service_fees, sum(f.amount) as revenue,  0 as forecasted_revenue, 0 as c3_revenue, 0 as c3_scanchange_rev, 0 as nyp_add_rev,
 0 as bulk_add_rev
 from fact_museum_tickets_unissued_fordate_new f, dim_date d, 
dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and f.ga_flag=1
and (g.account_idno like '%GAD%' or g.account_idno like '%TOU%')
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005')
and d.date_value >='20140521'
group by f.key_date
union
select f.key_date as key_date,0 as mus_service_fees,0 as mem_service_fees,0 as forecasted_service_fees,sum(f.amount) as revenue, 0 as forecasted_revenue, 0 as c3_revenue, 0 as c3_scanchange_rev, 0 as nyp_add_rev, 
 0 as bulk_add_rev
 from fact_museum_tickets_issued_fordate_new f, dim_date d, 
dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%GAD%' or g.account_idno like '%TOU%')
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005')
and f.ga_flag=1
and d.date_value>='20140521'
group by f.key_date

union
select f.key_date,0 as mus_service_fees,0 as mem_service_fees,0 as forecasted_service_fees, sum(f.amount) as revenue, 0 as forecasted_revenue, 0 as c3_revenue, 0 as c3_scanchange_rev, 0 as nyp_add_rev, 
 0 as bulk_add_rev
from fact_museum_tickets_issued_fordate_new f, dim_date d, 
dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=1
and d.date_value >= '20140521'
group by f.key_date
union
select f.key_date,0 as mus_service_fees,0 as mem_service_fees,0 as forecasted_service_fees, sum(f.amount) as revenue, 0 as forecasted_revenue, 0 as c3_revenue, 0 as c3_scanchange_rev, 0 as nyp_add_rev, 
 0 as bulk_add_rev
from fact_museum_tickets_unissued_fordate_new f, dim_date d, 
dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=1
and d.date_value >= '20140521'
group by f.key_date
union
select d.date_key as key_date ,0 as mus_service_fees,0 as mem_service_fees,0 as forecasted_service_fees,0 as revenue, sum(f.revenue) as forecasted_revenue, 0 as c3_revenue, 0 as c3_scanchange_rev, 0 as nyp_add_rev, 
 0 as bulk_add_rev
 from
fact_forecasted_value_for_date f, dim_date d
where f.key_date=d.date_value
and d.date_value >= '20140521'
group by d.date_key
UNION
select d.date_key as key_date ,0 as mus_service_fees,0 as mem_service_fees,0 as forecasted_service_fees,0 as revenue,  0 as forecasted_revenue,sum(quantity*amount) as c3_revenue, 0 as c3_scanchange_rev, 0 as nyp_add_rev, 
 0 as bulk_add_rev
from fact_museum_citypass f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and f.key_coupon_category in ('C3 Adult','C3 Youth')
and g.plu in ('CPBOOKAD007','CPBOOKYS007') 
and d.date_value >= '20160501'
group by d.date_key
UNION
select d.date_key as key_date ,0 as mus_service_fees,0 as mem_service_fees,0 as forecasted_service_fees,0 as revenue,  0 as forecasted_revenue,
0 as c3_revenue, sum(quantity * amount) as c3_scanchange_rev, 0 as nyp_add_rev,  0 as bulk_add_rev
from fact_museum_citypass_scanchange f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and f.key_coupon_category in ('C3 Adult','C3 Youth')
and d.date_value >= '20160501'
group by d.date_key
union
select d.date_key as key_date ,0 as mus_service_fees,0 as mem_service_fees,0 as forecasted_service_fees,0 as revenue,  0 as forecasted_revenue,
0 as c3_revenue, 0 as c3_scanchange_rev, sum(amount) as nyp_add_rev,  0 as bulk_add_rev
from fact_museum_nyp_add f, dim_date d
where f.key_date = d.date_key 
and d.date_value >= '20160501'
group by d.date_key
UNION
select d.date_key as key_date, 0 as mus_service_fees, 0 as mem_service_fees, 0 as forecasted_service_fees, 0 as revenue, 0 as forecasted_revenue, 0 as c3_revenue, 0 as c3_scanchange_rev, 0 as nyp_add_rev,
 sum(amount) as bulk_add_rev
from fact_bulk_tickets_add f,  dim_date d
where f.key_date = d.date_key
and d.date_value >='20170401'
group by d.date_key
union
select d.date_key as key_date, 0 as mus_service_fees, 0 as mem_service_fees, 0 as forecasted_service_fees, sum(amount) as revenue, 0 as forecasted_revenue, 0 as c3_revenue, 0 as c3_scanchange_rev, 0 as nyp_add_rev, 
0 as bulk_add_rev
from fact_museum_bulk_tickets_test f, dim_date d
where f.key_date = d.date_key
and d.date_value>= '20140521'
group by d.date_key
) A
where key_date < ?
group by key_date