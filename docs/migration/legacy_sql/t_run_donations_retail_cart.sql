-- TRANSFORMATION: t_run_donations_retail_cart
-- DESC: 

-- WRITES: 911DW:.fact_all_donations (InsertUpdate)


-- ===== STEP: ti: Mem Cart Donations [TableInput] conn=911DW =====
SELECT key_date, (sum(r.Amount)+sum(r.Return_Amount)) as donations
FROM 911dw.fact_retail r inner join 911dw.dim_facility f on f.key_facility = r.key_facility
inner join 911dw.dim_date d on r.key_date = d.date_key
WHERE 
r.key_item_descr in (483,5156,5179,482,485,2168,2169,2170,2171,2172,2173,3373,3375)
AND f.key_facility = 1020
AND r.key_summary_category = 6
AND d.date_value >= '20160101'
group by key_date