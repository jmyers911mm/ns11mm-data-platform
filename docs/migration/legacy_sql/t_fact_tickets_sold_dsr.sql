-- TRANSFORMATION: t_fact_tickets_sold_dsr
-- DESC: 

-- WRITES: 911DW:.fact_tickets_sold_dsr (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=Gateway =====
exec report.marketSegment @fromDate= ?,@thruDate= ?,@dateType=0