-- TRANSFORMATION: t_import_retail_budgets
-- DESC: 

-- WRITES: 911DW:.fact_retail_forecasts (InsertUpdate)


-- ===== STEP: Execute SQL script [ExecSQL] conn=911DW =====
update fact_retail_forecasts_test
set capture_rate = capture_rate * 100 
where year(key_date) = 2020