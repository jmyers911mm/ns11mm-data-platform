-- Verified Query: Ticket Utilization by Gate
-- Question: What is the ticket utilization rate by gate?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_gate_admissions, total_valid_scans, valid_scan_rate
  DIMENSIONS dim_gate.gate_name, dim_gate.location, dim_gate.is_members_only)
