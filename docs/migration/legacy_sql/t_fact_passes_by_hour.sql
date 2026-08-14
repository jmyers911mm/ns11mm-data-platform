-- TRANSFORMATION: t_fact_passes_by_hour
-- DESC: 

-- WRITES: 911DW:.fact_passes_by_hour (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=Gateway =====
exec report.fe_dailyScan_sh @fromDate= ?,@thruDate= ?