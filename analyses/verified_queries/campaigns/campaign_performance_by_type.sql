-- Verified Query: Campaign Performance by Type
-- Question: Which campaign types have the best open rates?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS avg_open_rate, avg_click_to_open_rate, total_emails_sent
  DIMENSIONS dim_campaign.campaign_type)
