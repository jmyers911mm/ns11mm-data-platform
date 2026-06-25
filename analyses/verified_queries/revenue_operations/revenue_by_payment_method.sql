-- Verified Query: Revenue by Payment Method
-- Question: How does revenue break down by payment method?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_ticket_revenue, total_tickets_sold
  DIMENSIONS dim_payment_method.payment_method_name, dim_payment_method.payment_category)
