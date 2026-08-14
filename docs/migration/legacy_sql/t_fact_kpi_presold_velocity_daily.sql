-- TRANSFORMATION: t_fact_kpi_presold_velocity_daily
-- DESC: 

-- WRITES: 911DW:.fact_kpi_presold (InsertUpdate)


-- ===== STEP: Items [TableInput] conn=911DW =====
SELECT
	DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 0 DAY), '%Y%m%d')			AS key_date,
    dt.time_interval  									AS 'time_interval'
   ,SUM(dt.presold_today)-SUM(dt.presold_yesterday) 	AS presold_diff
   ,((SUM(dt.presold_today)-SUM(dt.presold_yesterday))/NULLIF(SUM(dt.presold_yesterday),0))		AS velocity
FROM
(
SELECT
	 key_date			AS  key_date
    ,time_interval 		AS 'time_interval'
	,number_presold 	AS 'presold_today'
	,0  				AS 'presold_yesterday'
FROM fact_kpi_presold 
WHERE key_date = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 0 DAY), '%Y%m%d')
UNION
SELECT
	 key_date		    AS  key_date
	,time_interval		AS 'time_interval'
	,0  				AS 'presold_today'
	,number_presold     AS 'presold_yesterday'
FROM fact_kpi_presold 
WHERE key_date = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 1 DAY), '%Y%m%d')
)dt
GROUP BY dt.time_interval