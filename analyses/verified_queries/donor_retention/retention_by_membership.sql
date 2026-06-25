-- Verified Query: Retention By Membership
-- Question: What is retention by membership type?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_donor_retention
  METRICS avg_retention_rate
  DIMENSIONS retention.membership_type, retention.months_since_acquisition)
