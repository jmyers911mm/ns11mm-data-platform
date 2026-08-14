-- TRANSFORMATION: t_fact_update_donation_budgets
-- DESC: 

-- WRITES: 911DW:.fact_all_budgets (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=911DW =====
select key_date, sum(total_donations)
from
(select key_date, (donations_ticketing + coatcheck_donations + museum_exit_donations + cafe_donations) as total_donations
 from fact_dpr_forecasts
where key_date >= '20190101'
group by key_date
union 
select key_date, sum(donations) as total_donations
from fact_retail_forecasts
where key_date >= '20190101'
group by key_date) as A
group by key_date