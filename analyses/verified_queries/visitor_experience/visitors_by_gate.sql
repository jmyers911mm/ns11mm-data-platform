-- Verified Query: Visitors by Gate
-- Question: How many visitors enter through each gate?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_gate_admissions
  DIMENSIONS dim_gate.gate_name, dim_gate.location, dim_gate.is_members_only)
