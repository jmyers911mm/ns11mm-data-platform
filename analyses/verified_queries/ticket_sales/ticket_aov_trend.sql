-- Verified Query: Ticket AOV Trend
-- Question: What is the ticket average order value trend?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS ticket_aov, total_tickets_sold
  DIMENSIONS dates.month_name
  WHERE daily_ops.visit_date >= DATEADD('MONTH', -3, CURRENT_DATE))
