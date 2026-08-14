-- TRANSFORMATION: t_reporting_est_operating_expenses
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Estimated Operating Expenses - Actual & Budget [TableInput] conn=911DW =====
select key_date, sum(budgeted_expense) as est_operating_expenses, sum(budgeted_expense_budget_value) as est_operating_expenses_budget_value
from fact_budgeted_expenses f inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20141001'
group by key_date