-- Verified Query: Peak Demand Benchmarks
-- Question: Which time slots have the highest historical demand?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_donor_retention
  METRICS avg_reserved, p90_reserved, avg_utilization_pct
  DIMENSIONS benchmarks.ticket_type, benchmarks.day_of_week_name, benchmarks.entry_window_start)
