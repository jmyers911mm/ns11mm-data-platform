-- TRANSFORMATION: t_reporting_mus_attendance
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Museum attendance [TableInput] conn=911DW =====
SELECT key_date,
(CASE 
	WHEN (DAYOFWEEK(key_date) IN (3) OR key_date = '20220615') 
    AND SUM(v.passes_scanned) < 300
		THEN 0
	ELSE 
	    SUM(v.passes_scanned)
 END
 ) AS mus_attendance
FROM 911dw.fact_visitors v inner join 911dw.dim_date d on v.key_date = d.date_key
WHERE v.key_facility IN ( 1006,3000)
AND key_date >= '20210715'
GROUP BY key_date