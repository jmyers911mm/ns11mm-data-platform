-- TRANSFORMATION: t_fact_visitors_hourly_gateway
-- DESC: 

-- WRITES: Gateway Prod:report.fact_visitors_hourly_pentaho (InsertUpdate)


-- ===== STEP: Get_Fact_Visitors [TableInput] conn=911DW =====
SELECT
	key_date					AS key_date,
	DATE_FORMAT(key_date,"%Y%m%d") 	AS key_date_char,
	IFNULL(hourofday,0)			AS hourofday,	
	IFNULL(key_facility,0)		AS key_facility,	
	IFNULL(acp,0)				AS acp,	
	IFNULL(num_entry,0)			AS num_entry,
	IFNULL(num_exit,0)			AS num_exit,
	IFNULL(passes_scanned,0) 	AS passes_scanned
FROM fact_visitors_hourly
WHERE key_date = ?
AND key_facility = '1006'