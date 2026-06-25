-- Verified Query: LTV by Tier
-- Question: How many customers are in each LTV tier?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_customer_ltv, avg_lifetime_value
  DIMENSIONS customer_ltv.ltv_tier)
