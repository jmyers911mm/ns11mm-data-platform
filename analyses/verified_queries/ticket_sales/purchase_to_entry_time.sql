-- Verified Query: Purchase to Entry Time
-- Question: How long do visitors wait between buying a ticket and entering?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS avg_purchase_to_entry_minutes
  DIMENSIONS ticket_sales.ticket_type, ticket_sales.visitor_category)
