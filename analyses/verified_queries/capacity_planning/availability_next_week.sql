-- Verified Query: Availability Next Week
-- Question: What is ticket availability for the next week?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_donor_retention
  METRICS total_capacity, total_reserved, tickets_available
  DIMENSIONS availability.entry_date, availability.ticket_type, availability.demand_level
  WHERE availability.entry_date BETWEEN CURRENT_DATE AND DATEADD('DAY', 7, CURRENT_DATE))
