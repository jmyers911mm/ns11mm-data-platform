-- Verified Query: LTV by Customer Segment
-- Question: What is average lifetime value by customer segment?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS avg_lifetime_value, total_customer_ltv
  DIMENSIONS customers.customer_segment)
