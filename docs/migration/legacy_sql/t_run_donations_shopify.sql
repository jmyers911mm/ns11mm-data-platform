-- TRANSFORMATION: t_run_donations_shopify
-- DESC: 

-- WRITES: 911DW:.fact_all_donations (InsertUpdate)


-- ===== STEP: ti: Shopify Donations from Counterpoint [TableInput] conn=911DW =====
select key_date, sum(r.Amount) as donations 
from fact_retail r inner join  dim_date d on r.key_date = d.date_key
where r.key_facility = 1234
and r.key_summary_category = 6
and d.date_value >= '20190101'
group by key_date