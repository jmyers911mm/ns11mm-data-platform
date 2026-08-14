-- TRANSFORMATION: t_fact_visitors_estimate_multiplier
-- DESC: 

-- WRITES: 911DW:.fact_visitors_est_multiplier (InsertUpdate)


-- ===== STEP: Items [TableInput] conn=Gateway =====
SELECT 
	YEAR(DATEADD(DAY,-1, GETDATE()))	AS 'year',
	value_str		AS 'facility', 
	value_int2		AS 'month_number', 
	value_str2		AS 'month', 
	value_double	AS 'visitors_multiplier'
FROM report.maint_decode (NOLOCK)
WHERE code = 'MuseumSnapShotReport' 
AND decode = 'Mem_Visitors_EstToday'