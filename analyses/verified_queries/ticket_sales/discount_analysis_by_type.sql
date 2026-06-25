-- Verified Query: Discount Analysis by Ticket Type
-- Question: What percentage of tickets use discounts by type?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_ticket_discounts, total_ticket_revenue
  DIMENSIONS ticket_sales.ticket_type)
