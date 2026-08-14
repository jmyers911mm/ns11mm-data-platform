-- TRANSFORMATION: t_fact_earned_income_variance_values_table
-- DESC: 

-- WRITES: 911DW:.earned_income_report_analysis (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=911DW =====
select key_date,sum(mus_attendance), sum(forecasted_attend), (sum(mus_attendance)- sum(forecasted_attend)) as attend_diff,
sum(unissued_quantity + issued_quantity + mem_mus_issued_quantity + mem_mus_unissued_quantity+ c3_quantity+ c3_scanchange_ga_qty + bulk_scans_qty - child_evg_qty) as quantity, 
sum(forecast_value) as forecast_quantity, 
(sum(unissued_quantity + issued_quantity  + mem_mus_issued_quantity + mem_mus_unissued_quantity+ c3_quantity+ c3_scanchange_ga_qty + bulk_scans_qty - child_evg_qty) - sum(forecast_value)) as diff
from
(select v.key_date as key_date, sum(v.passes_scanned) as mus_attendance, 0 as forecasted_attend, 0 as unissued_quantity, 0 as issued_quantity,  0 as c3_quantity,
0 as mem_mus_issued_quantity, 0 as mem_mus_unissued_quantity, 0 as forecast_value, 0 as c3_scanchange_ga_qty, 0  as bulk_scans_qty, 0 as child_evg_qty
from fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and v.key_facility in (1006,3000)
AND d.date_value >= '20180101'
group by v.key_date
union
select f.key_date as key_date, 0 as mus_attendance, sum(f.new_attendance) as forecasted_attend,0 as unissued_quantity, 0 as issued_quantity,  0 as c3_quantity,
0 as mem_mus_issued_quantity, 0 as mem_mus_unissued_quantity, 0 as forecast_value, 0 as c3_scanchange_ga_qty, 0  as bulk_scans_qty, 0 as child_evg_qty
from fact_forecasted_value_for_date f, dim_date d
where f.key_date=d.date_key
and d.date_value >= '20180101'
group by f.key_date
union
select f.key_date as key_date, 0 as mus_attendance,0 as forecasted_attend,sum(f.quantity) as unissued_quantity, 0 as issued_quantity, 0 as c3_quantity,
0 as mem_mus_issued_quantity, 0 as mem_mus_unissued_quantity, 0 as forecast_value , 0 as c3_scanchange_ga_qty, 0  as bulk_scans_qty, 0 as child_evg_qty
from fact_museum_tickets_unissued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%GAD%' or g.account_idno like '%TOU%')
and g.account_idno not like '%XGA%'
and f.ga_flag=1
and g.plu not in ('CPBOOKYS011','CPBOOKYS010','CPBOOKAD011','CPBOOKAD010','MUSGADEXW001')
and d.date_value >= '20180101'
group by f.key_date
union
select f.key_date as key_date,0 as mus_attendance,0 as forecasted_attend,0 as unissued_quantity, sum(f.quantity) as issued_quantity,  0 as c3_quantity,
0 as mem_mus_issued_quantity, 0 as mem_mus_unissued_quantity,0 as forecast_value, 0 as c3_scanchange_ga_qty, 0  as bulk_scans_qty, 0 as child_evg_qty
 from fact_museum_tickets_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%GAD%' or g.account_idno like '%TOU%')
and g.account_idno not like '%XGA%'
and f.ga_flag=1
and g.plu not in ('CPBOOKYS011','CPBOOKYS010','CPBOOKAD011','CPBOOKAD010','MUSGADEXW001')
and d.date_value >= '20180101'
group by f.key_date
union
select f.key_date,0 as mus_attendance,0 as forecasted_attend,0 as unissued_quantity, 0 as issued_quantity,0 as c3_quantity, sum(f.quantity) as mem_mus_issued_quantity, 
0 as mem_mus_unissued_quantity, 0 as forecast_value, 0 as c3_scanchange_ga_qty, 0  as bulk_scans_qty, 0 as child_evg_qty
from fact_museum_tickets_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=1
and d.date_value >= '20180101'
group by f.key_date
union
select f.key_date,0 as mus_attendance,0 as forecasted_attend, 0 as unissued_quantity, 0 as issued_quantity,0 as c3_quantity,
0 as mem_mus_issued_quantity, sum(f.quantity) as mem_mus_unissued_quantity , 0 as forecast_value, 0 as c3_scanchange_ga_qty, 0  as bulk_scans_qty, 0 as child_evg_qty
from fact_museum_tickets_unissued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=1
and d.date_value >= '20180101'
group by f.key_date
union
select d.date_key as key_date,0 as mus_attendance,0 as forecasted_attend, 0 as unissued_quantity, 0 as issued_quantity, 0 as c3_quantity,
0 as mem_mus_issued_quantity,0 as mem_mus_unissued_quantity, sum(f.tickets_sold) as forecast_value, 0 as c3_scanchange_ga_qty, 0  as bulk_scans_qty , 0 as child_evg_qty
from fact_forecasted_value_for_date f, dim_date d
where f.key_date=d.date_value
and d.date_value >='20180101'
group by d.date_key
union
select d.date_key as key_date, 0 as mus_attendance, 0 as forecasted_attend, 0 as unissued_quantity, 0 as issued_quantity, 
sum(quantity) as c3_quantity,0 as mem_mus_issued_quantity,0 as mem_mus_unissued_quantity,0 as forecast_value, 0 as c3_scanchange_ga_qty, 0  as bulk_scans_qty, 0 as child_evg_qty
from fact_museum_citypass f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and f.key_coupon_category in ('C3 Adult','C3 Youth')
and g.plu in ('CPBOOKAD007','CPBOOKYS007') 
and d.date_value >= '20180101'
group by d.date_key
UNION
select d.date_key as key_date, 0 as mus_attendance, 0 as forecasted_attend, 0 as unissued_quantity, 0 as issued_quantity,
0 as c3_quantity,0 as mem_mus_issued_quantity,0 as mem_mus_unissued_quantity,0 as forecast_value, sum(quantity) as c3_scanchange_ga_qty, 0  as bulk_scans_qty, 0 as child_evg_qty
from fact_museum_citypass_scanchange f, dim_galaxy_items g, dim_date d
where f.key_date = d.date_key and
f.key_museum_category= g.key_category
and f.key_coupon_category in ('C3 Adult','C3 Youth')
and d.date_value >= '20180101'
group by d.date_key
union
select d.date_key as key_date, 0 as mus_attendance, 0 as forecasted_attend, 0 as unissued_quantity, 0 as issued_quantity,
0 as c3_quantity,0 as mem_mus_issued_quantity,0 as mem_mus_unissued_quantity,0 as forecast_value, 0 as c3_scanchange_ga_qty, sum(quantity) as bulk_scans_qty, 0 as child_evg_qty
from fact_museum_bulk_tickets_test f, dim_date d
where f.key_date = d.date_key and 
d.date_value >= '20180101'
group by d.date_key
union
select d.date_key as key_date, 0 as mus_attendance, 0 as forecasted_attend, 0 as unissued_quantity, 0 as issued_quantity,
0 as c3_quantity,0 as mem_mus_issued_quantity,0 as mem_mus_unissued_quantity,0 as forecast_value, 0 as c3_scanchange_ga_qty, 0 as bulk_scans_qty, sum(quantity) as child_evg_qty
from fact_museum_bulk_tickets_test f, dim_date d
where f.key_date = d.date_key
and (f.pricePointID = 84)
and d.date_value >= '20180101'
group by d.date_key
 ) A

where key_date < ?
group by key_date