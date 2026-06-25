-- Verified Query: Retention By Donor Tier
-- Question: What is the retention rate by donor tier?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_donor_retention
  METRICS avg_retention_rate, total_cohort_size
  DIMENSIONS retention.donor_tier, retention.months_since_acquisition)
