-- Verified Query: Half Life By Tier
-- Question: When do cohorts reach 50% retention?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_donor_retention
  METRICS avg_survival_rate
  DIMENSIONS survival.donor_tier, survival.months_since_acquisition, survival.is_half_life_month)
