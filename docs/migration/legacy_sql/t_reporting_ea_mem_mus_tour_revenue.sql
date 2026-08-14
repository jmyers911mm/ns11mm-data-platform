-- TRANSFORMATION: t_reporting_ea_mem_mus_tour_revenue
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Issued Early Access Memorial +MuseumTours & Revenue [TableInput] conn=911DW =====
select key_date, sum(f.quantity) as ea_mem_mus_tours, sum(f.amount) as ea_mem_mus_tour_revenue
from fact_museum_tickets_issued_fordate_new f inner join dim_date d on f.key_date =d.date_key
inner join dim_galaxy_items g on f.key_museum_category=g.key_category
where 
g.account_idno like '%TOU%'
and f.ga_flag=0
and g.plu in ('MUSGTOADW008')
and d.date_value >= '20201203'
group by key_date