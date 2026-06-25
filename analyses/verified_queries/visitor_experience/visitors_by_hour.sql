-- Verified Query: Visitors by Hour
-- Question: What are the busiest hours for visitors?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_gate_admissions
  DIMENSIONS traffic.scan_hour)
