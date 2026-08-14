-- TRANSFORMATION: t_set_last_run_date
-- DESC: 



-- ===== STEP: Add run to Drive Run ETL table [ExecSQL] conn=911DW =====
INSERT INTO stage_drive_etl
SELECT 
 'GA_911' AS SUBJ_ID,
 CURRENT_TIMESTAMP AS START_TS,
 (SELECT MAX(DATA_TO_TS) FROM stage_drive_etl WHERE SUBJ_ID = 'GA_911') AS DATA_FROM_TS,
 CURRENT_TIMESTAMP AS DATA_TO_TS 
FROM 
 DUAL;