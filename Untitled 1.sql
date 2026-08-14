SELECT CURRENT_DATABASE()                      AS checked_db,
       t.TABLE_SCHEMA,
       t.LAST_ALTERED                          AS fact_last_built,
       COUNT(c.COLUMN_NAME)                    AS has_ecom_gross_profit
FROM INFORMATION_SCHEMA.TABLES t
LEFT JOIN INFORMATION_SCHEMA.COLUMNS c
       ON c.TABLE_SCHEMA = t.TABLE_SCHEMA
      AND c.TABLE_NAME   = t.TABLE_NAME
      AND c.COLUMN_NAME  = 'ECOM_GROSS_PROFIT'
WHERE t.TABLE_SCHEMA = 'MARTS'
  AND t.TABLE_NAME   = 'fct_retail_performance'
GROUP BY 1,2,3;

SELECT * FROM SEMANTIC_VIEW(
  MARTS.DPR
  METRICS TOTAL_ECOM_GROSS_PROFIT
  DIMENSIONS DATE_DAY
) LIMIT 5;

-- 1. where does the view live, and when was it last replaced?
SHOW SEMANTIC VIEWS LIKE 'DPR' IN ACCOUNT;

-- 2. does the one you're reading actually carry the metric?
DESC SEMANTIC VIEW NS11MM_DW_DEV.MARTS.DPR;

USE DATABASE ;
USE SCHEMA MARTS;
-- then 8.6.0's scripts/deploy_semantic_view_dpr.sql


SHOW SEMANTIC VIEWS IN ACCOUNT;

SELECT "database_name", "schema_name", "name", "created_on"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "name" = 'DPR'
ORDER BY "created_on" DESC;