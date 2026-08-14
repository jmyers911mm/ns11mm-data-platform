-- TRANSFORMATION: t_reporting_mus_guided_tours_revenue
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Buyout Qty & Revenue [TableInput] conn=911DW =====
select key_date,  sum(f.quantity) as mus_tour_qty, sum(f.amount) as mus_tour_amount
from fact_museum_guided_tour_buyout f inner join dim_date d  on f.key_date=d.date_key
where 
f.key_museum_category in (1077,1430,1922,2226,2831,2826)
and d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: Issued Museum Guided Tours & Revenue [TableInput] conn=911DW =====
select key_date, sum(f.quantity) as mus_tour_qty, sum(f.amount) as mus_tour_amount
 from fact_museum_tickets_issued_fordate_new f inner join dim_date d on f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
g.account_idno like '%TOU%'
and f.ga_flag=0
and f.key_museum_category not in (1077,1430,1922,2112,2200,2201,2219,2220,2226,2227,2228,2229)
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005','MUSGTOFTAB001','MUSGTOFTAW001','MUSGTOFTCW001','MUSGTOFTNW001','MUSGTOFTYB001','MUSGTOFTYW001','MUSARCADW001', 'MUSGTOFTAC001','MUSGTOFTYC001', 'MUSGTOADW008', 'MUSGTOADW011')
and d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: Unissued Museum Guided Tours  & Revenue [TableInput] conn=911DW =====
select key_date, sum(f.quantity) as mus_tour_qty, sum(f.amount) as mus_tour_amount
 from fact_museum_tickets_unissued_fordate_new f inner join dim_date d on f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
g.account_idno like '%TOU%'
and f.ga_flag=0
and f.key_museum_category not in (1077,1430,1922,2112,2200,2201,2219,2220,2226,2227,2228,2229)
and g.plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005','MUSGTOFTAB001','MUSGTOFTAW001','MUSGTOFTCW001','MUSGTOFTNW001','MUSGTOFTYB001','MUSGTOFTYW001','MUSARCADW001', 'MUSGTOFTAC001','MUSGTOFTYC001', 'MUSGTOADW008', 'MUSGTOADW011')
and d.date_value >= '20140521'
group by key_date