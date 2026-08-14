-- TRANSFORMATION: t_reporting_mem_attendance
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Memorial attendance [TableInput] conn=911DW =====
SELECT key_date, SUM(v.passes_scanned) as mem_attendance
FROM 911dw.memorial_attendance v inner join 911dw.dim_date d on v.key_date = d.date_key
WHERE 
v.key_facility in (1000,2000)
and key_date >= '20110912'
group by key_date