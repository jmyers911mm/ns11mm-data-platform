-- TRANSFORMATION: t_import_budgets_err_dpr
-- DESC: 

-- WRITES: 911DW:.fact_forecasted_value_for_date (InsertUpdate)
-- WRITES: 911DW:.fact_dpr_forecasts (InsertUpdate)


-- ===== STEP: Execute SQL script [ExecSQL] conn=911DW =====
update fact_forecasted_value_for_date
set key_facility = 1003
where year(key_date) in (2025,2026)

-- ===== STEP: Execute SQL script 2 [ExecSQL] conn=911DW =====
UPDATE fact_dpr_forecasts
SET audio_tour_headsets_units_sold = audio_tour_headsets/(SELECT value_decimal FROM maint_decode WHERE code = 'Monthly_KPI' AND decode = 'AG_Units_Sold_K')
WHERE YEAR(key_date) = YEAR(CURDATE())