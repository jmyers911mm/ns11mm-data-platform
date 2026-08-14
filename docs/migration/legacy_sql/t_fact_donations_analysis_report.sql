-- TRANSFORMATION: t_fact_donations_analysis_report
-- DESC: 

-- WRITES: 911DW:.fact_donations_analysis_report (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=911DW =====
SELECT 
	monthname(key_date), 
	dayname(key_date),key_date, 
	sum(mem_attendance), 
	sum(mus_attendance), 
	(sum(ticketing_donations)  + sum(ticketing_donations_2)) as ticketing_donations, 
	sum(mus_store_visitors), sum(mus_store_don), 
	sum(mus_store_don) / sum(mus_store_visitors), 
	sum(mus_store_don) / sum(mus_attendance),
	sum(vesey_visitors), sum(vesey_donations), 
	sum(vesey_donations)/sum(vesey_visitors), 
	sum(retail_cart_donations) , sum(vs_cart_donations), 
	(sum(retail_cart_donations) + sum(vs_cart_donations)) as total_cart_donations,
	(sum(retail_cart_donations) + sum(vs_cart_donations))/ (sum(mem_attendance)- sum(mus_attendance)),
	sum(cafe_donations),
	sum(coatcheck_donations), 
	sum(coatcheck_donations)/ sum(mus_attendance), 
	sum(mus_exit_donations), 
	sum(mus_exit_donations) / sum(mus_attendance),
    sum(cafe1_donations) as cafe1_donations,
    sum(mus_plaza_box_don) as mus_plaza_box_don,
	sum(mem_cart_ask_don) as mem_cart_ask_don,
    sum(box_office_mus_exit_don) as box_office_mus_exit_don,
	sum(box_office_mem_don) as box_office_mem_don

FROM
(SELECT key_date,  SUM(v.passes_scanned) as mem_attendance, 0 as mus_attendance,0 as ticketing_donations, 0 as ticketing_donations_2,
0 as mus_store_visitors,0 as mus_store_don, 0 as vesey_visitors, 0 as vesey_donations, 
0 as retail_cart_donations, 0 as vs_cart_donations, 0 as cafe_donations, 
0 as coatcheck_donations,  0 as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
FROM 911dw.memorial_attendance v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and v.key_facility in (2000)
AND d.date_value >= '20140515'
group by key_date
union
SELECT key_date, 0 as mem_attendance, SUM(v.passes_scanned) as mus_attendance, 0 as ticketing_donations, 0 as ticketing_donations_2,
0 as mus_store_visitors,0 as mus_store_don, 0 as vesey_visitors, 0 as vesey_donations, 
0 as retail_cart_donations, 0 as vs_cart_donations, 0 as cafe_donations, 
0 as coatcheck_donations,  0 as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and v.key_facility in ( 1006,3000)
AND d.date_value >= '20140515'
group by key_date
union
select key_date, 0 as mem_attendance, 0 as mus_attendance,  sum(f.amount) as ticketing_donations_1, 0 as ticketing_donations_2,
0 as mus_store_visitors,0 as mus_store_don, 0 as vesey_visitors, 0 as vesey_donations, 
0 as retail_cart_donations, 0 as vs_cart_donations,  0 as cafe_donations,
0 as coatcheck_donations,  0 as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
from fact_museum_ticketing_donations_issued f, dim_date d
where f.key_date=d.date_key
and d.date_value >= '20140515'
and f.key_museum_category not in (1131,1359,1909,3220,3221)
group by key_date
union
select key_date, 0 as mem_attendance, 0 as mus_attendance, 0 as ticketing_donations_1,sum(f.amount) as ticketing_donations_2,
0 as mus_store_visitors,0 as mus_store_don,  0 as vesey_visitors, 0 as vesey_donations, 
0 as retail_cart_donations, 0 as vs_cart_donations, 0 as cafe_donations, 
0 as coatcheck_donations,  0 as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
from fact_museum_ticketing_donations_unissued f, dim_date d
where f.key_date=d.date_key 
and f.key_museum_category not in (1131,1359,1909)
and d.date_value >= '20140515'
group by key_date
union
SELECT key_date, 0 as mem_attendance, 0 as mus_attendance,0 as ticketing_donations, 0 as ticketing_donations_2,
SUM(v.num_entry) as mus_store_visitors,0 as mus_store_don, 0 as vesey_visitors, 0 as vesey_donations, 
0 as retail_cart_donations, 0 as vs_cart_donations, 0 as cafe_donations,  
0 as coatcheck_donations,  0 as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
  FROM 911dw.fact_visitors v, 911dw.dim_date d, 911dw.dim_facility f
  WHERE v.key_date = d.date_key
  AND v.key_facility = f.key_facility
  AND f.key_facility = 1007
  AND d.date_value >= '20140515'
group by key_date
union
SELECT key_date, 0 as mem_attendance, 0 as mus_attendance,0 as ticketing_donations, 0 as ticketing_donations_2, 
0 as mus_store_visitors, (sum(r.Amount)+sum(r.Return_Amount)) as mus_store_don, 0 as vesey_visitors, 0 as vesey_donations, 
0 as retail_cart_donations, 0 as vs_cart_donations,  0 as cafe_donations,
0 as coatcheck_donations,  0 as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
and r.key_item_descr in (483,5156,5179,482,485,2168,2169,2170,2171,2172,2173)
AND f.key_facility = 1003
AND r.key_summary_category = 6
AND d.date_value >= '20140515'
group by key_date
union
SELECT key_date, 0 as mem_attendance, 0 as mus_attendance,0 as ticketing_donations, 0 as ticketing_donations_2, 
0 as mus_store_visitors, 0 as mus_store_don, SUM(v.num_exit) as vesey_visitors,  0 as vesey_donations, 
0 as retail_cart_donations, 0 as vs_cart_donations,  0 as cafe_donations,
0 as coatcheck_donations,  0 as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
  FROM 911dw.fact_visitors v, 911dw.dim_date d, 911dw.dim_facility f
  WHERE v.key_date = d.date_key
  AND v.key_facility = f.key_facility
  AND f.key_facility = 1001
  AND d.date_value >= '20140515'
group by key_date
union
SELECT key_date, 0 as mem_attendance, 0 as mus_attendance,0 as ticketing_donations, 0 as ticketing_donations_2, 
0 as mus_store_visitors, 0 as mus_store_don, 0 as vesey_visitors, (sum(r.Amount)+sum(r.Return_Amount)) as vesey_donations, 
0 as retail_cart_donations, 0 as vs_cart_donations, 0 as cafe_donations,
0 as coatcheck_donations,  0 as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
and r.key_item_descr not in (583,598,886,931,2168,2169,2170,2171,2172,2173)
AND r.key_facility = 1001
AND r.key_summary_category = 6
AND d.date_value  >= '20140515'
group by key_date
union
SELECT key_date, 0 as mem_attendance, 0 as mus_attendance,0 as ticketing_donations, 0 as ticketing_donations_2, 
0 as mus_store_visitors, 0 as mus_store_don, 0 as vesey_visitors, 0 as vesey_donations, 
(sum(r.Amount)+sum(r.Return_Amount)) as retail_cart_donations, 0 as vs_cart_donations,0 as cafe_donations,
0 as coatcheck_donations,  0 as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
and r.key_item_descr in (483,5156,5179,482,485,2168,2169,2170,2171,2172,2173,3373,3375)
AND f.key_facility = 1020
AND r.key_summary_category = 6
AND d.date_value >= '20140515'
group by key_date
union
select key_date, 0 as mem_attendance, 0 as mus_attendance,0 as ticketing_donations, 0 as ticketing_donations_2, 
0 as mus_store_visitors, 0 as mus_store_don, 0 as vesey_visitors, 0 as vesey_donations,
0 as retail_cart_donaations,sum(f.amount) as vs_cart_donations, 0 as cafe_donations,
0 as coatcheck_donations,  0 as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
from fact_all_gateway_donations f, dim_date d, dim_galaxy_items g
where f.key_date=d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%DON-OPS-MEM%'
and d.date_value>= '20140515'
group by key_date
union
select key_date, 0 as mem_attendance, 0 as mus_attendance,0 as ticketing_donations, 0 as ticketing_donations_2, 
0 as mus_store_visitors, 0 as mus_store_don, 0 as vesey_visitors, 0 as vesey_donations,
0 as retail_cart_donaations,0 as vs_cart_donations, sum(donations) as cafe_donations, 
0 as coatcheck_donations,  0 as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
from cafe_performance c, dim_date d
where c.key_date=d.date_key
and d.date_value>= '20180101'
group by key_date
union
select key_date, 0 as mem_attendance, 0 as mus_attendance,0 as ticketing_donations, 0 as ticketing_donations_2, 
0 as mus_store_visitors, 0 as mus_store_don, 0 as vesey_visitors, 0 as vesey_donations, 
0 as retail_cart_donations, 0 as vs_cart_donations, 0 as cafe_donations,
sum(f.amount) as coatcheck_doantions, 0 as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
from fact_all_gateway_donations f, dim_date d, dim_galaxy_items g
where f.key_date=d.date_key
and f.key_museum_category=g.key_category
and g.account_idno like '%DON-OPS-MUS%'
and d.date_value >= '20140515'
group by key_date
union
select 
key_date, 0 as mem_attendance, 0 as mus_attendance,0 as ticketing_donations, 0 as ticketing_donations_2, 
0 as mus_store_visitors, 0 as mus_store_don, 0 as vesey_visitors, 0 as vesey_donations, 
0 as retail_cart_donations, 0 as vs_cart_donations, 0 as cafe_donations,
0 as coatcheck_donations, sum(r.Amount+r.Return_Amount) as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
from fact_retail r, dim_date d
where r.key_item_descr in ('886') 
and r.key_date=d.date_key 
and d.date_value >='20150129'
group by key_date
UNION
SELECT 
key_date, 0 as mem_attendance, 0 as mus_attendance,0 as ticketing_donations, 0 as ticketing_donations_2, 
0 as mus_store_visitors, 0 as mus_store_don, 0 as vesey_visitors, 0 as vesey_donations, 
0 as retail_cart_donations, 0 as vs_cart_donations, 0 as cafe_donations,
0 as coatcheck_donations, 0 as mus_exit_donations, 0  as cafe1_donations, sum(r.Amount+r.Return_Amount) as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
from fact_retail r, dim_date d
where r.key_item_descr in ('3375') 
and r.key_date=d.date_key 
and d.date_value >='20150129'
group by key_date
UNION
SELECT key_date, 0 as mem_attendance, 0 as mus_attendance,0 as ticketing_donations, 0 as ticketing_donations_2, 
0 as mus_store_visitors, 0 as mus_store_don, 0 as vesey_visitors, 0 as vesey_donations, 
0 as retail_cart_donations, 0 as vs_cart_donations,  0 as cafe_donations, 
0 as coatcheck_donations,  0 as mus_exit_donations, (sum(r.Amount)+sum(r.Return_Amount)) as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
and r.key_item_descr in (483,5156,5179,482,485,2168,2169,2170,2171,2172,2173)
AND f.key_facility = 4007
AND r.key_summary_category = 6
AND d.date_value >= '20221128'
group by key_date
UNION
SELECT 
key_date, 0 as mem_attendance, 0 as mus_attendance,0 as ticketing_donations, 0 as ticketing_donations_2, 
0 as mus_store_visitors, 0 as mus_store_don, 0 as vesey_visitors, 0 as vesey_donations, 
0 as retail_cart_donations, 0 as vs_cart_donations, 0 as cafe_donations,
0 as coatcheck_donations, 0 as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, sum(r.Amount+r.Return_Amount) as mem_cart_ask_don, 0 as box_office_mus_exit_don, 0 as  box_office_mem_don
from fact_retail r, dim_date d
where r.key_item_descr in ('483','5156','5179') 
and r.key_facility = 1020
and r.key_summary_category = 6
and r.key_date=d.date_key 
and d.date_value >='20150101'
group by key_date
union
select key_date, 0 as mem_attendance, 0 as mus_attendance,  0 as ticketing_donations_1, 0 as ticketing_donations_2,
0 as mus_store_visitors,0 as mus_store_don, 0 as vesey_visitors, 0 as vesey_donations, 
0 as retail_cart_donations, 0 as vs_cart_donations,  0 as cafe_donations,
0 as coatcheck_donations,  0 as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, sum(f.amount) as box_office_mus_exit_don, 0 as  box_office_mem_don
from fact_museum_ticketing_donations_issued f, dim_date d
where f.key_date=d.date_key
and d.date_value >= '20240215'
and f.key_museum_category = 3220
group by key_date
union
select key_date, 0 as mem_attendance, 0 as mus_attendance,  0 as ticketing_donations_1, 0 as ticketing_donations_2,
0 as mus_store_visitors,0 as mus_store_don, 0 as vesey_visitors, 0 as vesey_donations, 
0 as retail_cart_donations, 0 as vs_cart_donations,  0 as cafe_donations,
0 as coatcheck_donations,  0 as mus_exit_donations, 0  as cafe1_donations, 0 as mus_plaza_box_don, 0 as mem_cart_ask_don, 0 as box_office_mus_exit_don, sum(f.amount) as  box_office_mem_don
from fact_museum_ticketing_donations_issued f, dim_date d
where f.key_date=d.date_key
and d.date_value >= '20240215'
and f.key_museum_category = 3221
group by key_date
) as A
WHERE key_date < ?
GROUP BY key_date