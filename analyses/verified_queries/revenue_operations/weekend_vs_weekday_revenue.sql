-- Verified Query: Weekend vs Weekday Revenue
-- Question: How does weekend revenue compare to weekday?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_daily_revenue, total_daily_visitors, revenue_per_visitor
  DIMENSIONS dates.is_weekend)
