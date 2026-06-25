-- Verified Query: Fiscal Year Summary
-- Question: What is our fiscal year revenue summary?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_daily_revenue, total_daily_visitors, revenue_per_visitor
  DIMENSIONS dates.fiscal_year)
