-- TRANSFORMATION: t_reporting_early_access_tours_revenue_test
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Early Access Buyout [TableInput] conn=911DW =====
select f.key_date, sum(f.quantity) as early_access_tours, sum(f.amount) as early_access_tour_revenue
 from fact_museum_guided_tour_buyout f inner join dim_date d on f.key_date=d.date_key
where 
f.key_museum_category in (2112,2228)
and d.date_value >= '20160421'
group by f.key_date

-- ===== STEP: ti: Issued Early Access Tours & Revenue [TableInput] conn=911DW =====
select key_date, sum(f.quantity) as early_access_tours, sum(f.amount) as early_access_tour_revenue
from fact_museum_tickets_issued_fordate_new f inner join dim_date d on f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
g.account_idno like '%TOU%'
and f.ga_flag=0
and g.plu in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005','MUSGTOADW005')
and d.date_value >= '20160421'
group by key_date

-- ===== STEP: ti: Unissued Early Access Tours & Revenue [TableInput] conn=911DW =====
select key_date, sum(f.quantity) as early_access_tours, sum(f.amount) as early_access_tour_revenue
from fact_museum_tickets_unissued_fordate_new f inner join dim_date d on f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
g.account_idno like '%TOU%'
and f.ga_flag=0
and g.plu in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005','MUSGTOADW005')
and d.date_value >= '20160421'
group by key_date