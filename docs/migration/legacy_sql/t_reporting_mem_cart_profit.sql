-- TRANSFORMATION: t_reporting_mem_cart_profit
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: Memorial Cart  Cost [TableInput] conn=911DW =====
select key_date, sum(Cost) as cost
from
fact_cogs c inner join dim_date d on c.key_date = d.date_key
where c.key_facility=1020
and d.date_value >= '20140521'
group by key_date

-- ===== STEP: ti: Memorial Cart Sales [TableInput] conn=911DW =====
SELECT key_date, (sum(r.Amount)+sum(r.Return_Amount)) as sales
FROM 911dw.fact_retail r inner join 911dw.dim_facility f on f.key_facility = r.key_facility
inner join  911dw.dim_date d on r.key_date = d.date_key
WHERE 
f.key_facility = 1020
AND r.key_summary_category <> '6' 
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
AND d.date_value >= '20140521'
group by key_date