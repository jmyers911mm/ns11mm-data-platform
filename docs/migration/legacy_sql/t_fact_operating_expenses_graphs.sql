-- TRANSFORMATION: t_fact_operating_expenses_graphs
-- DESC: 

-- WRITES: 911DW:.earned_revenue_report_values (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=911DW =====
select key_date,budgeted_expense, budgeted_total_expense, budgeted_expense_budget_value, budgeted_total_expense_budget_value
from fact_budgeted_expenses f, dim_date d
where
f.key_date = d.date_key 
and d.date_value >= date_add(?,interval -65 day)