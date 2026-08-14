-- TRANSFORMATION: t_get_last_run_date_re
-- DESC: 



-- ===== STEP: Get last run date and current date [TableInput] conn=911DW =====
SELECT 
 IFNULL(DATE_FORMAT(DATE(MAX(DATA_TO_TS)),'%Y-%m-%d'),'2010-01-01') 'VAR_LAST_RUN_DATE'
FROM 
 stage_drive_etl
WHERE 
 SUBJ_ID = 'RE'