-- TRANSFORMATION: t_reporting_pass_revenue_new
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: C3 Revenue prior to scan change [TableInput] conn=911DW =====
select key_date, sum(quantity*amount) as pass_revenue
from fact_museum_citypass f inner join dim_galaxy_items g on f.key_museum_category= g.key_category
inner join dim_date d on f.key_date = d.date_key
where  
f.key_coupon_category in ('C3 Adult','C3 Youth')
and g.plu in ('CPBOOKAD007','CPBOOKYS007') 
and d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: CityPASS Booklet revenue [TableInput] conn=911DW =====
select key_date, sum(amount) as pass_revenue
from fact_museum_citypass_booklets f inner join dim_galaxy_items g on f.key_museum_category =g.key_category
inner join dim_date d on f.key_date=d.date_key
where 
g.plu in ('MUSGADADCP005', 'MUSGADYSCP005')
and d.date_value >= '20160601'
group by key_date

-- ===== STEP: ti: CityPASS Revenue (prior to scan change) [TableInput] conn=911DW =====
select key_date, sum(amount) as pass_revenue
from fact_museum_citypass f inner join dim_galaxy_items g on f.key_museum_category= g.key_category
inner join dim_date d on f.key_date = d.date_key
where  
f.key_coupon_category  in ('None', 'Adult','Youth')
and (g.account_idno like '%CPA%' or g.account_idno like '%CPB%')
and d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: CityPASS,C3 Revenue post scan change [TableInput] conn=911DW =====
select key_date, sum(quantity*amount) as pass_revenue
from fact_museum_citypass_scanchange f inner join dim_date d on f.key_date = d.date_key
where 
f.key_coupon_category in ('Adult', 'Youth','C3 Adult', 'C3 Youth')
and d.date_value >= '20160601'
group by key_date

-- ===== STEP: ti: New york Pass Additional Revenue [TableInput] conn=911DW =====
select cast(key_date as char(12)) as key_date, sum(amount) as pass_revenue
from fact_additional_revenue_new f inner join dim_date d on f.key_date =  d.date_key 
inner join dim_galaxy_items g on f.key_museum_category = g.key_category
where d.date_value >= '20140521'
and g.account_idno like '%GAD-NYA-NYA-OTH-XXX%'
group by key_date

-- ===== STEP: ti: Other Pass Revenue (Sighseeing, Explorer, New york pass) [TableInput] conn=911DW =====
select key_date, sum(f.amount) as pass_revenue
from fact_museum_tickets_issued_fordate_new f inner join dim_date d on  f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
 (g.account_idno like '%GAD%' or g.account_idno like '%TOU%')
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005')
and f.customer_id in ('20056','17522','23110','22361','29619')
and f.ga_flag=1
and d.date_value >= '20140521'
group by key_date