-- Verified Query: Survival Curve By Membership
-- Question: Show the donor survival curve by membership type
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_donor_retention
  METRICS avg_survival_rate
  DIMENSIONS survival.months_since_acquisition, survival.membership_type)
