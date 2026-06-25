-- Verified Query: Revenue by Day of Week
-- Question: What is total revenue by day of the week?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_daily_revenue, total_daily_visitors, revenue_per_visitor
  DIMENSIONS dates.day_of_week_name)
