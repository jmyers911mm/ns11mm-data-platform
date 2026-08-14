-- TRANSFORMATION: t_reporting_museum_audio_headset_revenue
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Audio Tour & Headset Revenue [TableInput] conn=911DW =====
SELECT
	dt.key_date AS key_date, 
	SUM(dt.audio_headset_revenue) AS audio_headset_revenue,
    SUM(dt.audio_headset_units_sold) AS audio_headset_units_sold
FROM
(
SELECT key_date, 
	   SUM(f.amount) AS audio_headset_revenue,
       SUM(f.quantity) AS audio_headset_units_sold
FROM fact_museum_audio_new f INNER JOIN dim_date d ON f.key_date=d.date_key 
WHERE key_date >= '20140515' AND key_date <> '20220503'
GROUP BY key_date
UNION
SELECT DATE_FORMAT(key_date,'%Y%m%d')  AS key_date,
	   SUM(musag_profit) AS audio_headset_revenue,
	SUM(musag_units_sold) AS audio_headset_units_sold
FROM fact_retail_analysis f 
WHERE f.key_date >= '2024-01-16'
GROUP BY f.key_date
)dt
GROUP BY dt.key_date