-- TRANSFORMATION: t_get_last_run_date
-- DESC: 



-- ===== STEP: Get last run date and current date [TableInput] conn=911DW =====
SELECT 
 IFNULL(DATE_FORMAT(DATE(MAX(DATA_TO_TS)),'%Y-%m-%d'),'2013-01-01') 'VAR_LAST_RUN_DATE',
 DATE_FORMAT((CURRENT_DATE),'%Y-%m-%d') 'VAR_CURR_DATE'
FROM 
 stage_drive_etl
WHERE 
 SUBJ_ID = 'GA_911'