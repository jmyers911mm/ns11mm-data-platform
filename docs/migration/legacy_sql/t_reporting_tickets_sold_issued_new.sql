-- TRANSFORMATION: t_reporting_tickets_sold_issued_new
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)
-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Get Bulk Tickets [TableInput] conn=911DW =====
select key_date, 
case when d.date_value = '20200911' then 0
else ifnull(sum(f.quantity),0) 
end as tickets
from fact_museum_bulk_tickets_test f inner join dim_date d on f.key_date = d.date_key 
where d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: Get C3 Tickets [TableInput] conn=911DW =====
select key_date, 
case when d.date_value = '20200911' then 0
else ifnull(sum(f.quantity),0) 
end as tickets
from fact_museum_citypass f inner join dim_galaxy_items g on f.key_museum_category= g.key_category
inner join  dim_date d on f.key_date = d.date_key
where  
f.key_coupon_category in ('C3 Adult','C3 Youth')
and g.plu in ('CPBOOKAD007','CPBOOKYS007') 
and key_date >= '20160501'
group by key_date

-- ===== STEP: ti: Get Child tickets from bulk tickets [TableInput] conn=911DW =====
select key_date,  
case when d.date_value = '20200911' then 0
else ifnull(sum(quantity),0) 
end as child_tickets
from fact_museum_bulk_tickets_test f inner join dim_date d on f.key_date =  d.date_key 
where f.pricePointID = 84
and d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: Get CityPASS Tickets before scan change [TableInput] conn=911DW =====
select key_date, 
case when d.date_value = '20200911' then 0
else ifnull(sum(f.quantity),0) 
end as tickets
from fact_museum_citypass f inner join dim_galaxy_items g on f.key_museum_category= g.key_category
inner join dim_date d on f.key_date = d.date_key
where  
(g.account_idno like '%CPA%' or g.account_idno like '%CPB%')
and d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: Get CityPASS/C3 Tickets post scan change [TableInput] conn=911DW =====
select key_date, 
case when d.date_value = '20200911' then 0
else ifnull(sum(f.quantity),0) 
end as tickets
from fact_museum_citypass_scanchange f inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20160601'
group by key_date

-- ===== STEP: ti: Get Issued Tickets [TableInput] conn=911DW =====
select key_date,
case when d.date_value = '20200911' then 0
else ifnull(sum(f.quantity),0) 
end as tickets
from fact_museum_tickets_issued_fordate_new f inner join dim_date d on f.key_date = d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where (g.account_idno like '%GAD%' or g.account_idno like '%TOU%')
and g.account_idno not like '%XGA%'
and f.ga_flag=1
and g.plu not in ('CPBOOKYS011','CPBOOKYS010','CPBOOKAD011','CPBOOKAD010','MUSGADEXW001')
and d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: Get Memorial Tour Mus Admission Issued Tickets [TableInput] conn=911DW =====
select key_date,  
case when d.date_value = '20200911' then 0
else ifnull(sum(f.quantity),0) 
end as tickets
from fact_museum_tickets_issued_fordate_new f, dim_date d, dim_galaxy_items g
where f.key_date =d.date_key
and f.key_museum_category=g.key_category
and (g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=1
and d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: Get Memorial Tour Mus Admission Unissued tickets [TableInput] conn=911DW =====
select key_date, 
case when d.date_value = '20200911' then 0
else ifnull(sum(f.quantity),0) 
end as tickets
from fact_museum_tickets_unissued_fordate_new f inner join dim_date d on f.key_date =d.date_key 
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
(g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=1
and d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: Get Unissued Tickets [TableInput] conn=911DW =====
select key_date, 
case when d.date_value = '20200911' then 0
else ifnull(sum(f.quantity),0) 
end as tickets
from fact_museum_tickets_unissued_fordate_new f inner join dim_date d on f.key_date = d.date_key
inner join dim_galaxy_items g on f.key_museum_category = g.key_category
where (g.account_idno like '%GAD%' or g.account_idno like '%TOU%')
and g.account_idno not like '%XGA%'
and f.ga_flag=1
and g.plu not in ('CPBOOKYS011','CPBOOKYS010','CPBOOKAD011','CPBOOKAD010','MUSGADEXW001')
and d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: Get the dates from dimension table [TableInput] conn=911DW =====
select date_key
from dim_date 
where date_value >='20140521'
and date_value <= ?