-- TRANSFORMATION: t_fact_update_visitors_estimate
-- DESC: 

-- WRITES: 911DW:.fact_visitors_hourly_estimate (InsertUpdate)


-- ===== STEP: Items [TableInput] conn=911DW =====
SELECT 
    vh.key_date 	AS key_date,
    1000 			AS key_facility,
	vh.hourofday 	AS hourofday,
    CAST((@RunTotal := @RunTotal + SUM(vh.num_entry)) AS DECIMAL(16, 2))*(
	SELECT visitors_multiplier FROM fact_visitors_est_multiplier  
	WHERE year =  YEAR(DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 1 DAY),"%Y%m%d"))
	AND month_number = MONTH(DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 1 DAY),"%Y%m%d")) AND facility='Memorial'
) AS visitors_est
FROM  fact_visitors_hourly vh
JOIN (SELECT @RunTotal := 0) AS RT
WHERE vh.key_date = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL - 1 DAY),"%Y%m%d")
AND vh.key_facility = '1006'
GROUP BY vh.key_date,vh.hourofday
ORDER BY vh.key_date,vh.hourofday