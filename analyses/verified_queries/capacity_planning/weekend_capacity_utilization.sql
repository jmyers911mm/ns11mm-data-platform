-- Verified Query: Weekend Capacity Utilization
-- Question: How does weekend utilization compare to weekday?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_donor_retention
  METRICS avg_utilization, total_capacity, total_reserved
  DIMENSIONS availability.is_weekend, availability.ticket_type)
