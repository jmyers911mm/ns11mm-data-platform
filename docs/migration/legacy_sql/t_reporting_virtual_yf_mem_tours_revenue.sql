-- TRANSFORMATION: t_reporting_virtual_yf_mem_tours_revenue
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Virtual Family Memorial Tours and Revenue [TableInput] conn=911DW =====
select f.key_date, sum(f.quantity) as virtual_yf_mem_tours , sum(f.amount) as virtual_yf_mem_tour_revenue
from fact_memorial_tours_issued_fordate_new f inner join dim_date d on f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
(g.account_idno like '%VTF%')
and f.ga_flag=0
and f.key_museum_category not in (1077,1430,1922,2112,2200,2201,2219,2220,2226,2227,2228,2229)
and d.date_value >= '20200701'
group by f.key_date