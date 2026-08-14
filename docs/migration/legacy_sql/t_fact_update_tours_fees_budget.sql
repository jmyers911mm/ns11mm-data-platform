-- TRANSFORMATION: t_fact_update_tours_fees_budget
-- DESC: 

-- WRITES: 911DW:.fact_all_budgets (InsertUpdate)


-- ===== STEP: Table input 3 [TableInput] conn=911DW =====
SELECT
  key_date
, key_facility
, mem_attendance
, attend
, new_attendance
, tickets_sold
, revenue
, guided_tours
, guided_tours_revenue
, service_fees
, citypass_tickets
, citypass_revenue
, mem_guided_tours
, mem_guided_tours_revenue
FROM fact_forecasted_value_for_date