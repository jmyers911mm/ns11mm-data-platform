-- Verified Query: Monthly Revenue Trend
-- Question: What is our monthly revenue trend?
-- Semantic View: NS11MM_DW_PROD.MARTS.SV_MUSEUM_OPERATIONS
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_daily_revenue, total_daily_visitors
  DIMENSIONS dates.month_name, dates.fiscal_year
  WHERE daily_ops.visit_date >= DATEADD('MONTH', -12, CURRENT_DATE))
