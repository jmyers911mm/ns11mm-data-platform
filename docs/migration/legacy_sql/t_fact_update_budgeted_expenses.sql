-- TRANSFORMATION: t_fact_update_budgeted_expenses
-- DESC: 

-- WRITES: 911DW:.fact_all_budgets (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=911DW =====
SELECT
  key_date
, budgeted_expense
FROM fact_budgeted_expenses
where key_date >= '20140515'