-- TRANSFORMATION: t_fact_dailyscan_data
-- DESC: 

-- WRITES: 911DW:.fact_dailyscan_data (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=Gateway =====
exec report.fe_dailyScan_ss @fromDate= ?,@thruDate= ?