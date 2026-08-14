-- TRANSFORMATION: t_reporting_mem_mus_tours_revenue
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Mem & Mus Tours & Revenue [TableInput] conn=911DW =====
select key_date, sum(quantity) as mem_mus_tours, sum(amount) as mem_mus_tour_revenue
from fact_memorial_museum_tour f inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20160701'
group by key_date