-- Verified Query: Customers by Membership Type
-- Question: How many customers by membership type?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_customers
  DIMENSIONS customers.membership_type, customers.customer_segment)
