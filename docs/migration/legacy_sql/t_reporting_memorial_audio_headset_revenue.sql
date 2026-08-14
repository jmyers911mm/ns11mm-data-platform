-- TRANSFORMATION: t_reporting_memorial_audio_headset_revenue
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Audio Tour & Headset Revenue [TableInput] conn=911DW =====
SELECT
	dt.key_date AS key_date, 
	SUM(dt.audio_headset_revenue) AS audio_headset_revenue
FROM
(
SELECT 
	key_date, 
	SUM(f.amount) AS audio_headset_revenue
FROM fact_memorial_audio_new f INNER JOIN dim_date d ON f.key_date=d.date_key 
WHERE f.key_date >= '20230404'
GROUP BY key_date
UNION
SELECT DATE_FORMAT(key_date,'%Y%m%d')  AS key_date,
	   SUM(mag_profit) AS audio_headset_revenue
FROM fact_retail_analysis f 
WHERE f.key_date >= '2023-09-04'
GROUP BY f.key_date
)dt
GROUP BY dt.key_date