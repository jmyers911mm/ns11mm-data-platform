-- TRANSFORMATION: t_dpr_excel_data_update
-- DESC: 

-- WRITES: 911DW:.fact_dpr_excel_data (InsertUpdate)
-- WRITES: 911DW:.fact_dpr_excel_data (InsertUpdate)
-- WRITES: 911DW:.fact_dpr_excel_data (InsertUpdate)
-- WRITES: 911DW:.fact_dpr_excel_data (InsertUpdate)
-- WRITES: 911DW:.fact_dpr_excel_data (InsertUpdate)
-- WRITES: 911DW:.fact_dpr_excel_data (InsertUpdate)
-- WRITES: 911DW:.fact_dpr_excel_data (InsertUpdate)


-- ===== STEP: ti: Actuals Memorial [TableInput] conn=911DW =====
select key_date
, sum(mem_attendance)
, sum(retail_carts_gross_profit)
, sum(ecom_gross_profit)
, ifnull(sum(virtual_mem_tour_revenue),0)+ ifnull(sum(virtual_yf_mem_tour_revenue),0) as mem_virtual_tour_rev
from fact_dpr_report_data
where key_date >= '20200704'
group by key_date
order by key_date

-- ===== STEP: ti: Forecasted values 1 [TableInput] conn=911DW =====
select key_date
, sum(mem_attendance)
, sum(new_attendance)
from fact_forecasted_value_for_date
where key_date >= '20200704'
group by key_date
order by key_date

-- ===== STEP: ti: Forecasted values 2 [TableInput] conn=911DW =====
select key_date 
, sum(tickets_sold_for_date)
, (ifnull(sum(ticket_revenue),0)+ifnull(sum(service_fees),0)+ifnull(sum(pass_revenue),0)) as ticket_revenue_budget
, sum(audio_tour_headsets)
from fact_dpr_forecasts
where key_date >= '20200911'
group by key_date
order by key_date

-- ===== STEP: ti: Actuals Museum [TableInput] conn=911DW =====
SELECT dpr.key_date as key_date
	, sum(dpr.mus_attendance) as mus_attendance
	, sum(dpr.tickets_sold) as tickets_sold
	, (ifnull(sum(dpr.ticket_revenue),0)+ ifnull(sum(dpr.pass_revenue),0)+ ifnull(sum(dpr.service_fees),0)) as total_adm_rev
	, sum(dpr.mus_store_gross_profit) as mus_store_gross_profit
	, sum(dpr.mus_guided_tour_revenue) as mus_guided_tour_revenue
	, sum(dpr.virtual_mus_tour_revenue) as virtual_mus_tour_revenue
	, sum(dpr.mem_field_trip_revenue) as mem_field_trip_revenue
	, sum(dpr.mus_field_trip_revenue) as mus_field_trip_revenue
	, sum(dpr.revealed_tour_revenue) as revealed_tour_revenue
	, sum(dpr.ask_educator_revenue) as ask_educator_revenue
    , sum(dpr.audio_tour_headset) as audio_tour_headset
	, sum(IFNULL(dt.cafe1_profit_all,0)) as cafe_profit
FROM  fact_dpr_report_data dpr LEFT JOIN  
(
	SELECT date_format(key_date,"%Y%m%d") as key_date,
		   cafe1_profit_all as cafe1_profit_all
	FROM fact_retail_analysis
	WHERE key_date > '2022-11-29' 
)dt
ON dpr.key_date=dt.key_date
WHERE dpr.key_date >= '20200911'
GROUP BY dpr.key_date
ORDER BY dpr.key_date

-- ===== STEP: ti: Retail Forecasts [TableInput] conn=911DW =====
select key_date, sum(mus_store_profit_budget), sum(retail_carts_profit_budget)
from
(select key_date, sum(profit_from_retail) as mus_store_profit_budget, 0 as retail_carts_profit_budget
from fact_retail_forecasts 
where key_facility = 1003
and key_date>='20200911'
group by key_date
union
select key_date, 0 as mus_store_profit_budget, sum(profit_from_retail) as retail_carts_profit_budget
from fact_retail_forecasts 
where key_facility = 1020
and key_date >= '20200704'
group by key_date)as A
group by key_date

-- ===== STEP: ti: Forecast values 3 [TableInput] conn=911DW =====
select key_date, sum(profit_from_ecom)
from fact_dpr_forecasts 
where key_date >= '20200704'
group by key_date

-- ===== STEP: ti: Donations Actuals [TableInput] conn=911DW =====
SELECT 
	key_date, 
	(sum(ms_donations) + sum(mus_exit_donations) + sum(ticketing_donations) + sum(cafe1_donations)) as mus_don,
	(sum(ecom_don)+sum(don_box) + sum(cart_don_ask)+sum(mask_don)) as mem_don
FROM
(SELECT key_date, (sum(r.Amount)+sum(r.Return_Amount)) as ms_donations, 0 as mus_exit_donations
, 0 as ticketing_donations, 0 as ecom_don, 0 as don_box, 0 as cart_don_ask, 0 as mask_don, 0 as cafe1_donations
FROM 911dw.fact_retail r 
inner join  911dw.dim_facility f on f.key_facility = r.key_facility
inner join 911dw.dim_date d on r.key_date = d.date_key
WHERE 
 r.key_item_descr in (483,482,485,2168,2169,2170,2171,2172,2173,3753)
AND f.key_facility = 1003
AND r.key_summary_category = 6
and d.date_value >= '20200911'
group by key_date
UNION
select key_date, 0 as ms_donations, sum(r.Amount+r.Return_Amount) as mus_exit_donations 
, 0 as ticketing_donations, 0 as ecom_don, 0 as don_box, 0 as cart_don_ask, 0 as mask_don, 0 as cafe1_donations
from fact_retail r inner join dim_date d on r.key_date=d.date_key
 where r.key_item_descr in ('886')  
 and d.date_value >= '20200911'
group by key_date
union
select key_date, 0 as ms_donations, 0 as mus_exit_donations, sum(amount) as ticketing_donations
, 0 as ecom_don, 0 as don_box, 0 as cart_don_ask, 0 as mask_don, 0 as cafe1_donations
from fact_museum_ticketing_donations_issued f inner join dim_date d
on f.key_date=d.date_key
where f.key_museum_category not in (1131,1359,1909)
and d.date_value >= '20200911'
group by key_date
UNION
select key_date, 0 as ms_donations, 0 as mus_exit_donations, 0 as ticketing_donations,
sum(r.Amount) as ecom_don, 0 as don_box, 0 as cart_don_ask, 0 as mask_don, 0 as cafe1_donations
from fact_retail r inner join  dim_date d on r.key_date = d.date_key
where r.key_facility = 1234
and r.key_summary_category = 6
and d.date_value >= '20200704'
group by key_date
union 
select key_date,  0 as ms_donations, 0 as mus_exit_donations, 0 as ticketing_donations,
0 as ecom_don,sum(mus_donation_box) as don_box, 0 as cart_don_ask, 0 as mask_don, 0 as cafe1_donations
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200704'
group by key_date
UNION
select key_date, 0 as ms_donations, 0 as mus_exit_donations, 0 as ticketing_donations,
0 as ecom_don, 0 as don_box, sum(cart_donation_ask) as cart_don_ask, 0 as mask_don, 0 as cafe1_donations
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200704'
group by key_date
union
select key_date, 0 as ms_donations, 0 as mus_exit_donations, 0 as ticketing_donations, 
0 as ecom_don, 0 as don_box, 0 as cart_don_ask, sum(mask_donations) as mask_don, 0 as cafe1_donations
from fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200911'
UNION
SELECT key_date, 0 as ms_donations, 0 as mus_exit_donations, 0 as ticketing_donations, 
0 as ecom_don, 0 as don_box, 0 as cart_don_ask, 0 as mask_don, (sum(r.Amount)+sum(r.Return_Amount)) as cafe1_donations
FROM 911dw.fact_retail r INNER JOIN 911dw.dim_facility f on f.key_facility = r.key_facility
INNER JOIN 911dw.dim_date d on r.key_date = d.date_key
WHERE r.key_item_descr in (483,482,485,2168,2169,2170,2171,2172,2173,3753)
AND f.key_facility = 4007
AND r.key_summary_category = 6
AND d.date_value >= '20221128'
GROUP BY key_date
) as A
group by key_date