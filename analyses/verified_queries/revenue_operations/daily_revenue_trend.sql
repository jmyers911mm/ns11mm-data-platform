-- Verified Query: Daily Revenue Trend
-- Question: What is our daily revenue trend this month?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_daily_revenue, total_daily_visitors
  DIMENSIONS dates.date_day
  WHERE daily_ops.visit_date >= DATE_TRUNC('month', CURRENT_DATE))
