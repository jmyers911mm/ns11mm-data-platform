-- TRANSFORMATION: t_run_donations_kiosk_coatcheck
-- DESC: 

-- WRITES: 911DW:.fact_all_donations (InsertUpdate)


-- ===== STEP: ti: Memorial Kiosk, Coatcheck [TableInput] conn=911DW =====
SELECT key_date, sum(amount) as donations
from fact_all_gateway_donations f inner join dim_date d on f.key_date = d.date_key
where f.key_date >= '20140515'
group by key_date