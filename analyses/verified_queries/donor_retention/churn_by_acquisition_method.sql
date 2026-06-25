-- Verified Query: Churn By Acquisition Method
-- Question: Which acquisition methods have the highest churn?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_donor_retention
  METRICS avg_churn_rate, total_cohort_size
  DIMENSIONS retention.acquisition_method)
