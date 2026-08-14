-- TRANSFORMATION: t_wifi_save_daily_data_dpr
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Daily WiFi DPR [TableInput] conn=911DW =====
SELECT  DATE_FORMAT(dt.key_date,'%Y%m%d') key_date,
        COUNT(DISTINCT dt.EMAIL_ADDRESS) AS daily_wifi_visitors
FROM
(
	SELECT key_date,
	       EMAIL_ADDRESS
	FROM stage_acceptance_uap_daily
	WHERE AUP_ACCEPTANCE = 'Guest user has accepted the use policy'
	AND MAC_ADDRESS IS NOT NULL
	AND NAD_ADDRESS IS NOT NULL
	AND EMAIL_ADDRESS IS NOT NULL
)dt
GROUP By key_date