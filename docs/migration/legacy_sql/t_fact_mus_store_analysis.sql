-- TRANSFORMATION: t_fact_mus_store_analysis
-- DESC: 

-- WRITES: 911DW:.fact_retail_analysis (InsertUpdate)
-- WRITES: 911DW:.fact_retail_analysis (InsertUpdate)
-- WRITES: 911DW:.fact_retail_analysis (InsertUpdate)
-- WRITES: 911DW:.fact_retail_analysis (InsertUpdate)
-- WRITES: 911DW:.fact_retail_analysis (InsertUpdate)
-- WRITES: 911DW:.fact_retail_analysis (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=911DW =====
SELECT 
		date_format(thedate, '%Y-%m-%d'), 
		sum(mus_visitors), 
		sum(mus_store_visitors), 
		(sum(mus_store_visitors)/sum(mus_visitors)) as capture_rate,
		sum(mus_store_customers), 
		(sum(mus_store_customers)/ sum(mus_store_visitors)) as conversion_rate, 
		sum(sales_mus_store) as sales_mus_store, 
		sum(cost_mus_store) as cost_mus_store,
		sum(water_mus_store) as water_ms,
		
		sum(sales_mus_store) - sum(cost_mus_store) as profit_mus_store, 
		((sum(sales_mus_store)) - sum(cost_mus_store)) / sum(mus_store_customers) as profit_per_cust_mus_store,
		sum(sales_mus_store)/sum(mus_store_customers) as mus_store_avg_sale,
		
		sum(sales_cafe1) as cafe1_sales_all, 
		sum(cafe1_customers) as cafe1_customers,
		(sum(sales_cafe1)-sum(costs_cafe1)) as cafe1_profit_all,

		sum(cafe_medallion_sales) as cafe_medallion_sales,
		sum(cafe_medallion_profit) as cafe_medallion_profit,
		sum(cafe_medallion_units_sold) as cafe_medallion_units_sold
    
FROM
(select f.key_date as thedate, sum(passes_scanned) as mus_visitors, 0 as mus_store_visitors, 0 as mus_store_customers,0 as sales_mus_store,0 as water_mus_store,
0 as cost_mus_store, 0 as sales_cafe1, 0 as cafe1_customers, 0  as costs_cafe1, 0 as cafe_medallion_sales, 0 as cafe_medallion_profit, 0 as cafe_medallion_units_sold
from fact_visitors f, dim_date d 
where f.key_date= d.date_key 
and key_facility in( 1006,3000) 
and d.date_value >= '20140515'
group by f.key_date
union
select f.key_date as thedate, 0 as mus_visitors, sum(num_entry) as mus_store_visitors, 0 as mus_store_customers, 0 as sales_mus_store,0 as water_mus_store,
0 as cost_mus_store, 0 as sales_cafe1, 0 as cafe1_customers, 0  as costs_cafe1, 0 as cafe_medallion_sales, 0 as cafe_medallion_profit, 0 as cafe_medallion_units_sold
from fact_visitors f, dim_date d
where  f.key_date = d.date_key 
and key_facility = 1007
and d.date_value >='20140515'
group by f.key_date
union 
select nt.key_date as thedate, 0 as mus_visitors, 0 as mus_store_visitors, sum(nt.Num_Tickets) as mus_store_customers,0 as sales_mus_store, 0 as water_mus_store,
0 as cost_mus_store, 0 as sales_cafe1, 0 as cafe1_customers, 0  as costs_cafe1, 0 as cafe_medallion_sales, 0 as cafe_medallion_profit, 0 as cafe_medallion_units_sold
FROM 911dw.fact_num_tickets nt, 911dw.dim_date d
WHERE nt.key_date = d.date_key
AND nt.key_facility = 1003
AND d.date_value >= '20140515'
group by nt.key_date
union
SELECT r.key_date as thedate,0 as mus_visitors, 0 as mus_store_visitors, 0 as mus_store_customers, (sum(r.Amount)+sum(r.Return_Amount)) as sales_mus_store,0 as water_mus_store,
0 as cost_mus_store, 0 as sales_cafe1, 0 as cafe1_customers, 0  as costs_cafe1, 0 as cafe_medallion_sales, 0 as cafe_medallion_profit, 0 as cafe_medallion_units_sold
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1003
AND r.key_summary_category <> '6' 
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
AND d.date_value >= '20140515'
group by r.key_date
union
SELECT r.key_date as thedate,0 as mus_visitors, 0 as mus_store_visitors, 0 as mus_store_customers, 0 as sales_mus_store, ((sum(r.Amount)+sum(r.Return_Amount))-sum(r.Cost)) as water_mus_store,
0 as cost_mus_store, 0 as sales_cafe1, 0 as cafe1_customers, 0  as costs_cafe1, 0 as cafe_medallion_sales, 0 as cafe_medallion_profit, 0 as cafe_medallion_units_sold
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1003
AND r.key_summary_category <> '6' 
and r.key_item_descr in ('4636')
AND d.date_value >= '20210501'
group by r.key_date
union
select fc.key_date as thedate, 0 as mus_visitors, 0 as mus_store_visitors, 0 as mus_store_customers, 0 as sales_mus_store, 0 as water_mus_store,
sum(Cost) as cost_mus_store, 0 as sales_cafe1, 0 as cafe1_customers, 0  as costs_cafe1, 0 as cafe_medallion_sales, 0 as cafe_medallion_profit, 0 as cafe_medallion_units_sold
from
fact_cogs fc, dim_date dd
where 
fc.key_date=dd.date_key
and dd.date_value>= '20140515'
and key_facility=1003
group by fc.key_date

union
SELECT r.key_date as thedate,0 as mus_visitors, 0 as mus_store_visitors, 0 as mus_store_customers, 0 as sales_mus_store,0 as water_mus_store,
0 as cost_mus_store, (sum(r.Amount)+sum(r.Return_Amount)) as sales_cafe1, 0 as cafe1_customers, 0  as costs_cafe1, 0 as cafe_medallion_sales, 0 as cafe_medallion_profit, 0 as cafe_medallion_units_sold
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 4007
AND r.key_summary_category <> '6' 
AND d.date_value >= '20221128'
group by r.key_date
union
select f.key_date as thedate, 0 as mus_visitors, 0 as mus_store_visitors, 0 as mus_store_customers, 0 as sales_mus_store,0 as water_mus_store,
0 as cost_mus_store, 0 as sales_cafe1, sum(num_tickets) as cafe1_customers, 0  as costs_cafe1, 0 as cafe_medallion_sales, 0 as cafe_medallion_profit, 0 as cafe_medallion_units_sold
from fact_num_tickets f, dim_date d
where  f.key_date = d.date_key 
and key_facility = 4007
and d.date_value >='20221128'
group by f.key_date
union
select c.key_date as thedate, 0 as mus_visitors, 0 as mus_store_visitors, 0 as mus_store_customers, 0 as sales_mus_store,0 as water_mus_store,
0 as cost_mus_store, 0 as sales_cafe1, 0 as cafe1_customers, sum(cost) as costs_cafe1, 0 as cafe_medallion_sales, 0 as cafe_medallion_profit, 0 as cafe_medallion_units_sold
from fact_cogs c inner join dim_date d on c.key_date = d.date_key
where c.key_facility=4007
and d.date_value >= '20221128'
group by key_date
union -- medallion_machine
SELECT mm.key_date as thedate,0 as mus_visitors, 0 as mus_store_visitors, 0 as mus_store_customers, 0 as sales_mus_store,0 as water_mus_store,
0 as cost_mus_store, 0 as sales_cafe1, 0 as cafe1_customers, 0  as costs_cafe1, IFNULL(mm.revenue,0) as cafe_medallion_sales,
IFNULL(mm.profit,0) as cafe_medallion_profit, IFNULL(mm.transactions,0) as cafe_medallion_units_sold
FROM 911dw.medallion_machine mm
WHERE mm.key_date >= '20231219'
group by mm.key_date
)as A
WHERE thedate < ?
GROUP BY thedate
ORDER BY thedate

-- ===== STEP: Table input 2 [TableInput] conn=911DW =====
SELECT 
		DATE_FORMAT(key_date,'%Y-%m-%d'), 
		SUM(mem_attendance), 
		SUM(cust_mem_cart), 
		(SUM(cust_mem_cart)/SUM(mem_attendance)) AS capture_rate, 
		SUM(sales_mem_cart) AS sales_mem_cart, 
		SUM(water_mem_cart),
		
		(SUM(sales_mem_cart) - SUM(cost_mem_cart))/SUM(cust_mem_cart) AS mem_cart_profit_per_cust,
		SUM(sales_mem_cart) - SUM(cost_mem_cart) AS profit_mem_cart, 
		SUM(sales_mem_cart)/SUM(cust_mem_cart) AS mem_cart_avg_sale,
		
		SUM(sales_mag) AS sales_mag,
		SUM(sales_mag) - SUM(cost_mag) AS profit_mag,
		SUM(cust_mag) AS cust_mag,
		SUM(mag_units_sold) AS units_sold_mag,

		SUM(sales_musag) AS sales_musag,
		SUM(sales_musag) - SUM(cost_musag) AS profit_musag,
		SUM(cust_musag) AS cust_musag,
		SUM(musag_units_sold) AS units_sold_musag,


		SUM(sales_mgt) AS sales_mgt,
		SUM(sales_mgt) - SUM(cost_mgt) AS profit_mgt,
		SUM(cust_mgt) AS cust_mgt,
		SUM(mgt_units_sold) AS units_sold_mgt,

		SUM(sales_mus_memberships) AS sales_mus_memberships,
		SUM(sales_mus_memberships) - SUM(cost_mus_memberships) AS profit_mus_memberships,
		SUM(cust_mus_memberships) AS cust_mus_memberships,
		SUM(mus_memberships_units_sold) AS units_sold_mus_memberships
FROM
(
SELECT key_date, SUM(v.passes_scanned) AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart, 0 AS water_mem_cart,0 AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,0 AS cust_mag,0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM 911dw.memorial_attendance v, 911dw.dim_date d
WHERE v.key_date = d.date_key
AND v.key_facility IN (1000,2000)
AND d.date_value >= '20140515'
GROUP BY key_date
UNION 
SELECT key_date, 0 AS mem_attendance, SUM(nt.Num_Tickets) AS cust_mem_cart, 0 AS sales_mem_cart, 0 AS water_mem_cart,0 AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,0 AS cust_mag,0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND d.date_value >= '20140515'
GROUP BY key_date
UNION
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, (sum(r.Amount)+sum(r.Return_Amount)) AS sales_mem_cart, 0 AS water_mem_cart, 0 AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,0 AS cust_mag,0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr NOT IN ('2449','2450','2451','2452','2453','2454')
AND d.date_value >= '20140515'
GROUP BY key_date
UNION
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart, ((SUM(r.Amount)+SUM(r.Return_Amount))-SUM(r.Cost)) AS water_mem_cart, 0 AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,0 AS cust_mag,0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
AND r.key_item_descr IN ('4636')
AND d.date_value >= '20210501'
GROUP BY key_date
UNION
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart,0 AS water_mem_cart, SUM(Cost) AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,0 AS cust_mag,0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM fact_cogs fc, dim_date dd
WHERE fc.key_date=dd.date_key
AND key_facility=1020
AND dd.date_value >= '20140515'
GROUP BY key_date
UNION
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart,0 AS water_mem_cart, 0 AS cost_mem_cart, SUM(Cost) AS cost_mag,0 AS sales_mag,0 AS cust_mag,0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM fact_cogs fc, dim_date dd
WHERE fc.key_date=dd.date_key
AND key_facility=1040
AND dd.date_value >= '20230904'
GROUP BY key_date
UNION
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart,0 AS water_mem_cart, 0 AS cost_mem_cart, 0 AS cost_mag,0 AS sales_mag,0 AS cust_mag,0 AS mag_units_sold, SUM(Cost) AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM fact_cogs fc, dim_date dd
WHERE fc.key_date=dd.date_key
AND key_facility=1060
AND dd.date_value >= '20230904'
GROUP BY key_date
UNION
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart,0 AS water_mem_cart, 0 AS cost_mem_cart, 0 AS cost_mag,0 AS sales_mag,0 AS cust_mag,0 AS mag_units_sold, 0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, SUM(Cost) AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM fact_cogs fc, dim_date dd
WHERE fc.key_date=dd.date_key
AND key_facility=1070
AND dd.date_value >= '20240116'
GROUP BY key_date
UNION
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart,0 AS water_mem_cart, 0 AS cost_mem_cart, 0 AS cost_mag,0 AS sales_mag,0 AS cust_mag,0 AS mag_units_sold, SUM(Cost) AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, SUM(Cost) AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM fact_cogs fc, dim_date dd
WHERE fc.key_date=dd.date_key
AND key_facility=1080
AND dd.date_value >= '20240116'
GROUP BY key_date
UNION
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart, 0 AS water_mem_cart, 0 AS cost_mem_cart,0 AS cost_mag,SUM(r.Amount)+SUM(r.Return_Amount) AS sales_mag,0 AS cust_mag,0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1040
AND r.key_summary_category <> '6'
and r.key_item_descr NOT IN ('2449','2450','2451','2452','2453','2454','4636')
AND d.date_value >= '20230904'
GROUP BY key_date
UNION
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart, 0 AS water_mem_cart, 0 AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,0 AS cust_mag,0 AS mag_units_sold,0 AS cost_musag,SUM(r.Amount)+SUM(r.Return_Amount) AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1060
AND r.key_summary_category <> '6'
and r.key_item_descr NOT IN ('2449','2450','2451','2452','2453','2454','4636')
AND d.date_value >= '20230904'
GROUP BY key_date
UNION
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart, 0 AS water_mem_cart, 0 AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,0 AS cust_mag,0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,SUM(r.Amount)+SUM(r.Return_Amount) AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1070
AND r.key_summary_category <> '6'
AND r.key_item_descr IN ('5096')
AND d.date_value >= '20240116'
GROUP BY key_date
UNION
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart, 0 AS water_mem_cart, 0 AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,0 AS cust_mag,0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,SUM(r.Amount)+SUM(r.Return_Amount) AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1080
AND r.key_summary_category <> '6'
AND r.key_item_descr IN ('2449', '2450', '2451', '2452', '2453', '2454')
AND d.date_value >= '20240116'
GROUP BY key_date
UNION
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart, 0 AS water_mem_cart, 0 AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,0 AS cust_mag, SUM(QTY)+SUM(Return_QTY) AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1040
AND r.key_summary_category <> '6'
and r.key_item_descr NOT IN ('2449','2450','2451','2452','2453','2454','4636')
AND d.date_value >= '20230904'
GROUP BY key_date
UNION
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart, 0 AS water_mem_cart, 0 AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,0 AS cust_mag, 0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,SUM(QTY)+SUM(Return_QTY) AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1060
AND r.key_summary_category <> '6'
and r.key_item_descr NOT IN ('2449','2450','2451','2452','2453','2454','4636')
AND d.date_value >= '20230904'
GROUP BY key_date
UNION
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart, 0 AS water_mem_cart, 0 AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,0 AS cust_mag, 0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,SUM(QTY)+SUM(Return_QTY) AS musag_units_sold, 0 AS cost_mtg,0 AS sales_mtg,0 AS cust_mtg,SUM(QTY)+SUM(Return_QTY) AS mtg_units_sold,
0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1070
AND r.key_summary_category <> '6'
AND r.key_item_descr IN ('5096')
AND d.date_value >= '20240116'
GROUP BY key_date
UNION
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart, 0 AS water_mem_cart, 0 AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,0 AS cust_mag, 0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,SUM(QTY)+SUM(Return_QTY) AS musag_units_sold, 0 AS cost_mtg,0 AS sales_mtg,0 AS cust_mtg,0 AS mtg_units_sold,
0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,SUM(QTY)+SUM(Return_QTY) AS mus_memberships_units_sold
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1080
AND r.key_summary_category <> '6'
AND r.key_item_descr IN ('2449', '2450', '2451', '2452', '2453', '2454')
AND d.date_value >= '20240116'
GROUP BY key_date
UNION 
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart, 0 AS water_mem_cart,0 AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,SUM(nt.Num_Tickets) AS cust_mag,0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1040
AND d.date_value >= '20230904'
GROUP BY key_date
UNION 
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart, 0 AS water_mem_cart,0 AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,0 AS cust_mag,0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,SUM(nt.Num_Tickets) AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1060
AND d.date_value >= '20230904'
GROUP BY key_date
UNION 
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart, 0 AS water_mem_cart,0 AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,0 AS cust_mag,0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,SUM(nt.Num_Tickets) AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,0 AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1070
AND d.date_value >= '20240116'
GROUP BY key_date
UNION 
SELECT key_date, 0 AS mem_attendance, 0 AS cust_mem_cart, 0 AS sales_mem_cart, 0 AS water_mem_cart,0 AS cost_mem_cart,0 AS cost_mag,0 AS sales_mag,0 AS cust_mag,0 AS mag_units_sold,0 AS cost_musag,0 AS sales_musag,0 AS cust_musag,0 AS musag_units_sold, 0 AS cost_mgt,0 AS sales_mgt,0 AS cust_mgt,0 AS mgt_units_sold, 0 AS cost_mus_memberships,0 AS sales_mus_memberships,SUM(nt.Num_Tickets) AS cust_mus_memberships,0 AS mus_memberships_units_sold
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1080
AND d.date_value >= '20240116'
GROUP BY key_date
) AS A
WHERE key_date < ?
GROUP BY key_date

-- ===== STEP: Table input 3 [TableInput] conn=911DW =====
select date_format(key_date,'%Y-%m-%d'), sum(ms_vis), sum(ms_cust), sum(ms_conversion_rate) as ms_conversion_rate, sum(ms_avg_sale) as ms_avg_sale,
 (sum(ms_capture_rate)) as ms_capture_rate, sum(profit_ms), sum(vesey_vis),
sum(vesey_cust), (sum(vesey_conversion_rate)/100) as vesey_conversion_rate,  sum(vesey_avg_sale), sum(profit_vesey), 
sum(mem_cart_cust),  sum(mem_cart_avg_sale), sum(profit_mem_cart)
from
(select key_date, visitors as ms_vis, customers as ms_cust, conversion_rate as ms_conversion_rate, capture_rate as ms_capture_rate, revenue as ms_sales,
profit_from_retail as profit_ms, average_sale as ms_avg_sale, 0 as vesey_vis, 0 as vesey_cust, 0 as vesey_conversion_rate,
 0 as vesey_avg_sale, 0 as profit_vesey,  0 as mem_cart_cust,  0 as mem_cart_avg_sale, 0 as profit_mem_cart
from fact_retail_forecasts f, dim_date d
where f.key_date=d.date_key
and f.key_facility = 1003
and d.date_value >= '20170101'
group by key_date
union
select key_date, 0 as ms_vis, 0 as ms_cust, 0 as ms_conversion_rate, 0 as ms_capture_rate, 0 as ms_sales,
 0 as profit_ms, 0 as ms_avg_sale, visitors as vesey_vis, customers as vesey_cust, conversion_rate as vesey_conversion_rate, 
average_sale as vesey_avg_sale, profit_from_retail as profit_vesey,  0 as mem_cart_cust, 0 as mem_cart_avg_sale, 0 as profit_mem_cart
from fact_retail_forecasts f, dim_date d
where f.key_date=d.date_key
and f.key_facility = 1001
and d.date_value >= '20170101'
group by key_date
union
select key_date, 0 as ms_vis, 0 as ms_cust, 0 as ms_conversion_rate, 0 as ms_capture_rate, 0 as ms_sales,
 0 as profit_ms, 0 as ms_avg_sale, 0 as vesey_vis, 0 as vesey_cust, 0 as vesey_conversion_rate, 
0 as vesey_avg_sale, 0 as profit_vesey  , customers as mem_cart_cust,  average_sale as mem_cart_avg_sale, profit_from_retail as profit_mem_cart
from fact_retail_forecasts f, dim_date d
where f.key_date=d.date_key
and f.key_facility = 1020
and d.date_value >= '20170101'
group by key_date
) as A
where key_date < ?
group by key_date

-- ===== STEP: Table input 4 [TableInput] conn=911DW =====
select date_format(key_date,'%Y-%m-%d'), sum(visitors) as visitors, sum(customers) as customers, (sum(customers)/sum(visitors)) as conversion_rate, 
(sum(sales) - sum(cost)) as profit, sum(sales)/ sum(customers) as avg_sale, (sum(sales)- sum(cost))/ sum(customers) as profit_per_cust
from
(SELECT key_date, SUM(v.num_exit) as visitors, 0 as customers, 0 as sales, 0 as cost
  FROM 911dw.fact_visitors v, 911dw.dim_date d, 911dw.dim_facility f
  WHERE v.key_date = d.date_key
  AND v.key_facility = f.key_facility
  AND f.key_facility = 1001
  AND d.date_value >= '20140521'
group by key_date
union
SELECT key_date, 0 as visitors, SUM(nt.Num_Tickets) as customers, 0 as sales, 0 as cost
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1001
AND d.date_value >= '20140521'
group by key_date
union
SELECT key_date, 0 as visitors, 0 as customers, (sum(r.Amount)+sum(r.Return_Amount)) as sales, 0 as cost
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND r.key_facility = 1001
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454') 
AND d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as visitors, 0 as customers, 0 as sales,   sum(Cost) as cost
    from
    fact_cogs fc, dim_date dd
    where 
    fc.key_date=dd.date_key
       and key_facility=1001
 and dd.date_value >= '20140521'
group by key_date) as A
where key_date < ?
group by key_date

-- ===== STEP: Table input 5 [TableInput] conn=911DW =====
select date_format(key_date,'%Y-%m-%d') , (sum(shopify_orders) + sum(drupal_orders)+sum(ecom_cp_orders)) as ecom_orders, sum(ecom_sales)/ (sum(shopify_orders) + sum(drupal_orders)+sum(ecom_cp_orders)) as ecom_avg_sale
, sum(ecom_profit), sum(ecom_profit)/(sum(shopify_orders) + sum(drupal_orders) +sum(ecom_cp_orders)), sum(ecom_sales) as ecom_total_sales,
sum(budget_ecom_orders),
sum(budget_ecom_profit), (sum(budget_sales_ecom) / sum(budget_ecom_orders)) as budget_ecom_avg_sale
from
(select key_date, count(distinct order_id) as shopify_orders,0 as ecom_cp_orders, 0 as drupal_orders, 0 as ecom_sales, 0 as ecom_profit, 0 as budget_ecom_orders, 0 as budget_ecom_profit, 0 as budget_sales_ecom
from fact_shopify_orders o, dim_date d
where o.key_date=d.date_key
and d.date_value >= '20160315'
and d.date_value <'20170701'
group by key_date
union
select key_date, 0 as shopify_orders, sum(f.Num_Tickets) as ecom_cp_orders,0 as drupal_orders, 0 as ecom_sales, 0 as ecom_profit, 0 as budget_ecom_orders, 0 as budget_ecom_profit, 0 as budget_sales_ecom
from fact_num_tickets f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1234
and d.date_value >='20170701'
group by key_date
union
select key_date, 0 as shopify_orders,0 as ecom_cp_orders, count(distinct order_id) as drupal_orders, 0 as ecom_sales, 0 as ecom_profit, 0 as budget_ecom_orders, 0 as budget_ecom_profit, 0 as budget_sales_ecom
from fact_ecommerce_2 fe,  dim_date dd
where  dd.date_key = fe.key_date
and fe.key_category <> 6
and fe.key_item_description not in(3368,3367,3369,3370,3371,3385,2935)
and dd.date_value >= '20140521'
group by key_date
union
select key_date,0 as shopify_orders,0 as ecom_cp_orders, 0 as drupal_orders,  sales as ecom_sales, profit as ecom_profit, 0 as budget_ecom_orders, 0 as budget_ecom_profit, 0 as budget_sales_ecom
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1234
and d.date_value >= '20140521'
group by key_date
union
select key_date, 0 as shopify_orders,0 as ecom_cp_orders, 0 as drupal_orders, 0 as ecom_sales, 0 as ecom_profit, 
ecom_orders as budget_ecom_orders, profit_from_ecom as budget_ecom_profit, total_sales_ecom as budget_sales_ecom
from fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and d.date_value >= '20160101'
group by key_date) as A
where key_date < ?
group by key_date
order by key_date

-- ===== STEP: Table input 6 [TableInput] conn=911DW =====
select key_date, (mus_store_visitors - budget_mus_store_visitors), (ms_capture_rate - budget_ms_capture_rate), (mus_store_customers - budget_mus_store_customers),
(ms_conversion_rate - budget_ms_conversion_rate), (profit_mus_store - budget_profit_mus_store), (mus_store_avg_sale - budget_mus_store_avg_sale),
(vesey_visitors - budget_vesey_visitors), (vesey_customers - budget_vesey_customers) , (vesey_conversion_rate - budget_vesey_conversion_rate), 
(profit_vesey- budget_profit_vesey) , (vesey_avg_sale - budget_vesey_avg_sale) , (ecom_orders - budget_ecom_orders) , (ecom_avg_sale - budget_ecom_avg_sale),(ecom_profit - budget_ecom_profit),
(mem_cart_customers - budget_mem_cart_customers), (mem_cart_profit - budget_mem_cart_profit), (mem_cart_avg_sale- budget_mem_cart_avg_sale)
  from fact_retail_analysis f
where f.key_date >= '20140521'
and f.key_date < ?
group by f.key_date