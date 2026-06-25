-- Verified Query: Ticket Revenue by Type
-- Question: What is ticket revenue broken down by ticket type?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_ticket_revenue, total_tickets_sold, ticket_aov
  DIMENSIONS ticket_sales.ticket_type)
