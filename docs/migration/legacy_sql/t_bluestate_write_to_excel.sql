-- TRANSFORMATION: t_bluestate_write_to_excel
-- DESC: 

-- EXCEL OUT: /opt/pentaho/exports/bluestate/Blue_State_WiFi_Email_List_Export tmpl=template.xls


-- ===== STEP: ti:Get data from table [TableInput] conn=911DW =====
SELECT DISTINCT
	aud.key_date	   		  AS 'Date', 
    LOWER(aud.EMAIL_ADDRESS)  AS USER_NAME,
    IFNULL(FIRST_NAME,'')	  AS FIRST_NAME,
    IFNULL(LAST_NAME,'')      AS LAST_NAME
FROM  stage_acceptance_uap_daily aud
WHERE AUP_ACCEPTANCE = 'Guest user has accepted the use policy'
  AND MAC_ADDRESS IS NOT NULL
  AND NAD_ADDRESS IS NOT NULL
  AND EMAIL_ADDRESS IS NOT NULL
  AND key_date >= DATE_ADD(CURDATE(), INTERVAL - 7 DAY)
  AND key_date < DATE_ADD(CURDATE(), INTERVAL - 0 DAY)
  GROUP BY aud.key_date,LOWER(aud.EMAIL_ADDRESS) 
  ORDER BY aud.key_date