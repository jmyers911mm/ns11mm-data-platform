-- TRANSFORMATION: t_reporting_mus_donation_box
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Donation Box [TableInput] conn=911DW =====
SELECT key_date, (sum(r.Amount)+sum(r.Return_Amount)) as mus_donation_box
FROM 911dw.fact_retail r inner join 911dw.dim_facility f on f.key_facility = r.key_facility
inner join  911dw.dim_date d on r.key_date = d.date_key
WHERE 
r.key_item_descr= 3375
AND d.date_value >= '20150101'
group by key_date