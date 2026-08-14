-- TRANSFORMATION: t_reporting_youth_fam_tours_revenue
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Issued Youth Fam Tours & Revenue [TableInput] conn=911DW =====
select key_date, sum(f.quantity) as youth_fam_tours, sum(f.amount) as youth_fam_tour_revenue
from fact_museum_tickets_issued_fordate_new f inner join dim_date d on f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
g.account_idno like '%TOU%'
and f.ga_flag=0
and g.plu in ('MUSGTOFTAB001','MUSGTOFTAW001','MUSGTOFTCW001','MUSGTOFTNW001','MUSGTOFTYB001','MUSGTOFTYW001', 'MUSGTOFTAC001','MUSGTOFTYC001',
 'MUSGTOFTAW001',  'MUSGTOFTAW002',  'MUSGTOFTMW001',  'MUSGTOFTSW001',  'MUSGTOFTTW001', 'MUSGTOFTVW001')
and d.date_value >= '20160701'
group by key_date

-- ===== STEP: ti: Unissued Youth Fam Tours & Revenue [TableInput] conn=911DW =====
select key_date, sum(f.quantity) as youth_fam_tours, sum(f.amount) as youth_fam_tour_revenue
from fact_museum_tickets_unissued_fordate_new f inner join dim_date d on f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
g.account_idno like '%TOU%'
and f.ga_flag=0
and g.plu in ('MUSGTOFTAB001','MUSGTOFTAW001','MUSGTOFTCW001','MUSGTOFTNW001','MUSGTOFTYB001','MUSGTOFTYW001', 'MUSGTOFTAC001','MUSGTOFTYC001',
 'MUSGTOFTAW001',  'MUSGTOFTAW002',  'MUSGTOFTMW001',  'MUSGTOFTSW001',  'MUSGTOFTTW001', 'MUSGTOFTVW001')
and d.date_value >= '20160701'
group by key_date