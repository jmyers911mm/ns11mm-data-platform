-- TRANSFORMATION: t_fact_update_retail_budgets_2
-- DESC: 

-- WRITES: 911DW:.fact_all_budgets (InsertUpdate)


-- ===== STEP: Table input 5 [TableInput] conn=911DW =====
SELECT
  key_date, profit_from_retail 

FROM fact_retail_forecasts
where key_facility = 1020