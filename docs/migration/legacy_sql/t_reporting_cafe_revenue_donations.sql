-- TRANSFORMATION: t_reporting_cafe_revenue_donations
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Cafe Revenue [TableInput] conn=911DW =====
select key_date, sum(revenue) as cafe_revenue 
from cafe_performance c inner join dim_date d on c.key_date = d.date_key
where d.date_value >= '20141001' and d.date_value < '20231001'
group by key_date