-- TRANSFORMATION: t_run_donations_cafe
-- DESC: 

-- WRITES: 911DW:.fact_all_donations (InsertUpdate)


-- ===== STEP: ti: Cafe Donations [TableInput] conn=911DW =====
select key_date, donations 
from cafe_performance c inner join dim_date d on c.key_date=d.date_key
where d.date_value >= '20180101'
and d.date_value < '20230101'
group by key_date