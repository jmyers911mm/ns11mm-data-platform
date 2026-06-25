-- Verified Query: At Risk Cohorts
-- Question: Which cohorts are at risk?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_donor_retention
  METRICS avg_survival_rate, total_original_cohort, total_surviving
  DIMENSIONS survival.cohort_month, survival.cohort_health)
