-- Verified Query: Net Revenue After Discounts
-- Question: What is our net revenue after discounts?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_ticket_revenue, total_ticket_discounts, total_retail_revenue, total_retail_discounts
  DIMENSIONS dates.month_name, dates.fiscal_year
  WHERE daily_ops.visit_date >= DATEADD('MONTH', -6, CURRENT_DATE))
