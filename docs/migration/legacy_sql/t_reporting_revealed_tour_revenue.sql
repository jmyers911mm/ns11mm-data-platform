-- TRANSFORMATION: t_reporting_revealed_tour_revenue
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Revealed Tours and Revenue [TableInput] conn=911DW =====
select f.key_date, sum(f.quantity) as revealed_tours , sum(f.amount) as revealed_tour_revenue
from fact_memorial_tours_issued_fordate_new f inner join dim_date d on f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
(g.account_idno like '%VTM%')
and f.ga_flag=0
and g.plu = 'VTMUSOBLOADW001'
and d.date_value >= '20210301'
group by f.key_date