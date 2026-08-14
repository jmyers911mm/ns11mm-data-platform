-- TRANSFORMATION: t_reporting_mem_guided_tours_revenue
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Issued Memorial Tour with Mus Admission Tickets and Revenue [TableInput] conn=911DW =====
select f.key_date, sum(f.quantity) as mem_tours, sum(f.amount) as mem_tour_revenue
from fact_museum_tickets_issued_fordate_new f inner join dim_date d on f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
(g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=0
and d.date_value >= '20140521'
group by f.key_date

-- ===== STEP: ti: Issued Memorial Tours & Revenue [TableInput] conn=911DW =====
select f.key_date, sum(f.quantity) as mem_tours , sum(f.amount) as mem_tour_revenue
from fact_memorial_tours_issued_fordate_new f inner join dim_date d on f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
(g.account_idno like '%MGT%' and g.account_idno like '%XGA%')
and f.ga_flag=0
and f.key_museum_category not in (1077,1430,1922,2112,2200,2201,2219,2220,2226,2227,2228,2229)
and d.date_value >= '20140521'
group by f.key_date

-- ===== STEP: ti: Memorial Tour Buyout Qty & Revenue [TableInput] conn=911DW =====
select f.key_date, sum(f.quantity) as mem_tours, sum(f.amount) as mem_tour_revenue
 from fact_museum_guided_tour_buyout f inner join dim_date d on f.key_date=d.date_key
where 
f.key_museum_category in (2219,2220)
and d.date_value >= '20170101'
group by f.key_date

-- ===== STEP: ti: Unissued Memorial Tour with Mus Admission Tickets & Revenue [TableInput] conn=911DW =====
select f.key_date, sum(f.quantity) as mem_tours, sum(f.amount) as mem_tour_revenue
from fact_museum_tickets_unissued_fordate_new f inner join dim_date d on f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
(g.account_idno like '%MGT%' and g.account_idno like '%XXX%')
and f.ga_flag=0
and d.date_value >= '20140521'
group by f.key_date

-- ===== STEP: ti: Unissued Memorial Tours and Revenue [TableInput] conn=911DW =====
select f.key_date, sum(f.quantity) as mem_tours , sum(f.amount) as mem_tour_revenue
from fact_memorial_tours_unissued_fordate_new f inner join dim_date d on f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
(g.account_idno like '%MGT%' and g.account_idno like '%XGA%')
and f.ga_flag=0
and f.key_museum_category not in (1077,1430,1922,2112,2200,2201,2219,2220,2226,2227,2228,2229)
and d.date_value >= '20140521'
group by f.key_date