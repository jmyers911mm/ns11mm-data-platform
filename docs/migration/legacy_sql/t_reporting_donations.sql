-- TRANSFORMATION: t_reporting_donations
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: ti: t_reporting_donations [TableInput] conn=911DW =====
SELECT 
	dt.key_date as key_date,
	sum(dt.box_offce_donations+ 
        dt.ticketing_donations+ 
        dt.mus_exit_donations+ 
        dt.mus_store_donations+ 
        dt.kiosk_coatcheck_donations+ 
        dt.mus_cart_donations+ 
        dt.cafe_donations+
        dt.shopify_donations+ 
        dt.cafe1_donations
    ) AS donations
FROM
(
-- (includes FAT, Box office donations)
select 
key_date, sum(f.amount) as box_offce_donations, 0 as ticketing_donations, 0 as mus_exit_donations, 0 as mus_store_donations, 0 as kiosk_coatcheck_donations, 0 as mus_cart_donations, 0 as cafe_donations, 0 as shopify_donations, 0 as cafe1_donations
from fact_museum_ticketing_donations_issued f inner join dim_date d
on f.key_date=d.date_key
where f.key_museum_category not in (1131,1359,1909)
and d.date_value >= '20140521'
group by key_date
UNION
-- ti: Unissued Ticketing Donations
select key_date, 0 as box_offce_donations, sum(f.amount) as ticketing_donations, 0 as mus_exit_donations, 0 as mus_store_donations, 0 as kiosk_coatcheck_donations, 0 as mus_cart_donations, 0 as cafe_donations, 0 as shopify_donations, 0 as cafe1_donations
from fact_museum_ticketing_donations_unissued f inner join dim_date d
on f.key_date=d.date_key
where f.key_museum_category not in (1131,1359,1909)
and d.date_value >= '20140521'
group by key_date
UNION
-- ti: Museum Exit Donations
SELECT 
a.key_date, 0 as box_offce_donations, 0 as ticketing_donations, SUM(a.donations) AS mus_exit_donations, 0 as mus_store_donations, 0 as kiosk_coatcheck_donations, 0 as mus_cart_donations, 0 as cafe_donations, 0 as shopify_donations, 0 as cafe1_donations
FROM
(
SELECT key_date,   r.key_item_descr,
CASE r.key_item_descr WHEN '886' THEN SUM(r.Amount+r.Return_Amount) ELSE 0 END AS  donations 
FROM dim_date d LEFT JOIN fact_retail r ON r.key_date=d.date_key
WHERE 
	r.key_date >='20150129' 
AND r.key_date < curdate()
GROUP BY key_date, r.key_item_descr
)a GROUP BY a.key_date
UNION
-- ti: Museum Store Donations
SELECT key_date, 0 as box_offce_donations, 0 as ticketing_donations, 0 as mus_exit_donations, (sum(r.Amount)+sum(r.Return_Amount)) as mus_store_donations, 0 as kiosk_coatcheck_donations, 0 as mus_cart_donations, 0 as cafe_donations, 0 as shopify_donations, 0 as cafe1_donations
FROM 911dw.fact_retail r inner join  911dw.dim_facility f on f.key_facility = r.key_facility
inner join 911dw.dim_date d on r.key_date = d.date_key
WHERE 
 r.key_item_descr in (483,482,485,2168,2169,2170,2171,2172,2173,3753)
AND f.key_facility = 1003
AND r.key_summary_category = 6
AND d.date_value >= '20140515'
group by key_date
UNION
-- ti: Memorial Kiosk, Coatcheck
SELECT key_date, 0 as box_offce_donations, 0 as ticketing_donations, 0 as mus_exit_donations, 0 as mus_store_donations, sum(amount) as kiosk_coatcheck_donations, 0 as mus_cart_donations, 0 as cafe_donations, 0 as shopify_donations, 0 as cafe1_donations
from fact_all_gateway_donations f inner join dim_date d on f.key_date = d.date_key
where f.key_date >= '20140515'
group by key_date
UNION
-- ti: Mem Cart Donations
SELECT key_date, 0 as box_offce_donations, 0 as ticketing_donations, 0 as mus_exit_donations, 0 as mus_store_donations, 0 as kiosk_coatcheck_donations, (sum(r.Amount)+sum(r.Return_Amount)) as mus_cart_donations, 0 as cafe_donations, 0 as shopify_donations, 0 as cafe1_donations
FROM 911dw.fact_retail r inner join 911dw.dim_facility f on f.key_facility = r.key_facility
inner join 911dw.dim_date d on r.key_date = d.date_key
WHERE 
r.key_item_descr in (483,482,485,2168,2169,2170,2171,2172,2173,3373,3375)
AND f.key_facility = 1020
AND r.key_summary_category = 6
AND d.date_value >= '20160101'
group by key_date
UNION
-- ti: Cafe Donations
select key_date, 0 as box_offce_donations, 0 as ticketing_donations, 0 as mus_exit_donations, 0 as mus_store_donations, 0 as kiosk_coatcheck_donations, 0 as mus_cart_donations, donations as cafe_donations, 0 as shopify_donations, 0 as cafe1_donations
from cafe_performance c inner join dim_date d on c.key_date=d.date_key
where d.date_value >= 20180101
and d.date_value <= 20230101
-- and d.date_value <> ?
group by key_date
UNION
-- ti: Shopify Donations from Counterpoint
select key_date, 0 as box_offce_donations, 0 as ticketing_donations, 0 as mus_exit_donations, 0 as mus_store_donations, 0 as kiosk_coatcheck_donations, 0 as mus_cart_donations, 0 as cafe_donations, sum(r.Amount) as shopify_donations, 0 as cafe1_donations
from fact_retail r inner join  dim_date d on r.key_date = d.date_key
where r.key_facility = 1234
and r.key_summary_category = 6
and d.date_value >= '20190101'
group by key_date
UNION
-- ti: Cafe1_Donations
SELECT a.key_date, 0 as box_offce_donations, 0 as ticketing_donations, 0 as mus_exit_donations, 0 as mus_store_donations, 0 as kiosk_coatcheck_donations, 0 as mus_cart_donations, 0 as cafe_donations, 0 as shopify_donations, sum(a.donations) as cafe1_donations
FROM
(
SELECT key_date, (sum(r.Amount)+sum(r.Return_Amount)) as donations
FROM 911dw.fact_retail r INNER JOIN 911dw.dim_facility f on f.key_facility = r.key_facility
INNER JOIN 911dw.dim_date d on r.key_date = d.date_key
WHERE r.key_item_descr in (483,482,485,2168,2169,2170,2171,2172,2173,3753)
AND f.key_facility = 4007
AND r.key_summary_category = 6
AND d.date_value >= '20221128'
GROUP BY key_date
)a
GROUP BY a.key_date
)AS dt
WHERE key_date < CURDATE()
GROUP BY key_date
ORDER BY key_date