-- TRANSFORMATION: t_fact_visitors_minutely
-- DESC: 

-- WRITES: 911DW:.fact_visitors_minutely (InsertUpdate)


-- ===== STEP: Get_Fact_Visitors_Min [TableInput] conn=911DW =====
SELECT
	DATE_FORMAT(key_date,"%Y%m%d") 	AS key_date,
	CURTIME() 						AS time_created,
	IFNULL(hourofday,0)				AS hourofday,	
	IFNULL(key_facility,0)			AS key_facility,	
	SUM(IFNULL(num_entry,0)	)		AS num_entry,
	SUM(IFNULL(num_exit,0))			AS num_exit
FROM fact_visitors_hourly
WHERE key_date = ?
AND key_facility = '1006'
GROUP BY key_date,hourofday
ORDER BY hourofday DESC
LIMIT 1