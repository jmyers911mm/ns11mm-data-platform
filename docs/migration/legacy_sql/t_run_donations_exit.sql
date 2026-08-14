-- TRANSFORMATION: t_run_donations_exit
-- DESC: 

-- WRITES: 911DW:.fact_all_donations (InsertUpdate)


-- ===== STEP: ti: Museum Exit Donations [TableInput] conn=911DW =====
SELECT 
    dt.key_date AS key_date, 
    SUM(dt.donations) AS donations
FROM
(
	SELECT key_date, SUM(r.Amount + r.Return_Amount) AS donations
    FROM    fact_retail r
    INNER JOIN dim_date d ON r.key_date = d.date_key
    WHERE 
        r.key_item_descr IN ('886')
    AND d.date_value >= '20150129'
    GROUP BY key_date 
    UNION 
    SELECT key_date, box_office_mus_exit_don AS donations
    FROM   fact_donations_analysis_report
    WHERE  key_date >= '20150129'
) dt
GROUP BY dt.key_date