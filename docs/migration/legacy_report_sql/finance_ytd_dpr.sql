-- REPORT: DPR - YTD (finance_ytd_dpr)

-- ===== [datasources/sql-ds.xml] query: Master =====
SELECT 

(select sum(mem_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mem_attendance_ytd
,
(select sum(mem_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as mem_attendance_ytd_py
,
(select sum(mus_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mus_attendance_ytd
,
(select sum(mus_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as mus_attendance_ytd_py
,
(select sum(tickets_sold)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as tickets_sold_ytd
,
(select sum(tickets_sold)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as tickets_sold_ytd_py
,
(select (sum(ticket_revenue)+ sum(pass_revenue)- sum(citypass_revenue))
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as ticket_revenue_ytd
,
(select (sum(ticket_revenue)+ sum(pass_revenue)- sum(citypass_revenue))
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as ticket_revenue_ytd_py
,
(select  sum(citypass_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as citypass_revenue_ytd
,
(select sum(citypass_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as citypass_revenue_ytd_py
,
(select sum(service_fees)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as service_fees_ytd
,
(select sum(service_fees)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as service_fees_ytd_py
,
(select sum(mus_guided_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mus_guided_tours_ytd
,
(select sum(mus_guided_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as mus_guided_tours_ytd_py
,
(select sum(mus_guided_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mus_guided_tour_revenue_ytd
,
(select sum(mus_guided_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as mus_guided_tour_revenue_ytd_py
,
(select sum(mem_guided_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mem_guided_tours_ytd
,
(select sum(mem_guided_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as mem_guided_tours_ytd_py
,
(select sum(mem_guided_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mem_guided_tour_revenue_ytd
,
(select sum(mem_guided_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as mem_guided_tour_revenue_ytd_py
,
(select sum(early_access_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as early_access_tours_ytd
,
(select sum(early_access_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as early_access_tours_ytd_py
,
(select sum(early_access_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as early_access_tour_revenue_ytd
,
(select sum(early_access_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as early_access_tour_revenue_ytd_py
,
(select sum(youth_fam_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as youth_fam_tours_ytd
,
(select sum(youth_fam_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as youth_fam_tours_ytd_py
,
(select sum(youth_fam_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as youth_fam_tour_revenue_ytd
,
(select sum(youth_fam_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as youth_fam_tour_revenue_ytd_py
,
(select sum(mem_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mem_mus_tours_ytd

,
(select sum(mem_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as mem_mus_tours_ytd_py
,
(select sum(mem_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mem_mus_tour_revenue_ytd
,
(select sum(mem_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as mem_mus_tour_revenue_ytd_py
,
(select sum(virtual_mem_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mem_vt_ytd
,
(select sum(virtual_mem_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mem_vt_rev_ytd
,
(select sum(virtual_yf_mem_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as yf_vt_ytd
,
(select sum(virtual_yf_mem_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as yf_vt_rev_ytd
,
(select sum(sales_mus_store)
from 
fact_retail_analysis f
where year(f.key_date) = year(${today}) 
and f.key_date <= ${today} ) as sales_mus_store_ytd
,
(select sum(sales_mus_store)
from 
fact_retail_analysis f
where
year(f.key_date) = year(${sameDateLastYear})
and f.key_date <= ${sameDateLastYear} ) as sales_mus_store_ytd_py
,
(select sum(mus_store_visitors)
from 
fact_retail_analysis f
where year(f.key_date) = year(${today}) 
and f.key_date <= ${today} ) as visitors_mus_store_ytd
,
(select sum(mus_store_visitors)
from 
fact_retail_analysis f
where
year(f.key_date) = year(${sameDateLastYear})
and f.key_date <= ${sameDateLastYear} ) as visitors_mus_store_ytd_py
,
(select sum(mus_store_customers)
from 
fact_retail_analysis f
where year(f.key_date) = year(${today}) 
and f.key_date <= ${today} ) as customers_ms_ytd
,
(select sum(mus_store_customers)
from 
fact_retail_analysis f
where
year(f.key_date) = year(${sameDateLastYear})
and f.key_date<= ${sameDateLastYear} ) as customers_ms_ytd_py
,
(select sum(mus_store_gross_profit)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mus_store_gross_profit_ytd
,
(select sum(mus_store_gross_profit)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as mus_store_gross_profit_ytd_py
,
(select sum(sales_mem_cart)
from 
fact_retail_analysis f
where year(f.key_date) = year(${today}) 
and f.key_date <= ${today} ) as sales_retail_cart_ytd
,
(select sum(sales_mem_cart)
from 
fact_retail_analysis f
where
year(f.key_date) = year(${sameDateLastYear})
and f.key_date <= ${sameDateLastYear} ) as sales_retail_cart_ytd_py
,
(select sum(mem_cart_customers)
from 
fact_retail_analysis f
where year(f.key_date) = year(${today}) 
and f.key_date <= ${today} ) as customers_retail_cart_ytd
,
(select sum(mem_cart_customers)
from 
fact_retail_analysis f
where
year(f.key_date) = year(${sameDateLastYear})
and f.key_date<= ${sameDateLastYear} ) as customers_retail_cart_ytd_py

,
(select sum(retail_carts_gross_profit)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as retail_carts_gross_profit_ytd
,
(select sum(retail_carts_gross_profit)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as retail_carts_gross_profit_ytd_py
,
(select sum(ecom_orders)
from 
fact_retail_analysis f
where year(f.key_date) = year(${today}) 
and f.key_date <= ${today} ) as ecom_orders_ytd
,
(select sum(ecom_orders)
from 
fact_retail_analysis f
where
year(f.key_date) = year(${sameDateLastYear})
and f.key_date<= ${sameDateLastYear} ) as ecom_orders_ytd_py
,
(select sum(ecom_gross_profit)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as ecom_gross_profit_ytd
,
(select sum(ecom_gross_profit)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as ecom_gross_profit_ytd_py
,
(select sum(audio_tour_headset)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as audio_tour_headset_ytd
,
(select sum(audio_tour_headset)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as audio_tour_headset_ytd_py
,
(select sum(ticketing_donations)
from fact_all_donations f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as ticketing_donations_ytd
,
(select sum(ticketing_donations)
from fact_all_donations f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as ticketing_donations_ytd_py
,
(select sum(kiosk_coatcheck_donations)
from fact_all_donations f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as coatcheck_donations_ytd
,
(select sum(kiosk_coatcheck_donations)
from fact_all_donations f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as coatcheck_donations_ytd_py
,
(select sum(mus_exit_donations)
from fact_all_donations f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mus_exit_donations_ytd
,
(select sum(mus_exit_donations)
from fact_all_donations f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as mus_exit_donations_ytd_py
,
(SELECT sum(dt.donations) 
FROM
(SELECT sum(f.Amount) as donations
FROM 911dw.fact_museum_ticketing_donations_issued f INNER JOIN 911dw.dim_date d ON f.key_date = d.date_key
WHERE f.key_museum_category = 3221
AND d.year4 = year(${today}) 
AND d.date_value <= ${today}
UNION
select sum(mus_store_donations) as donations
from fact_all_donations f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} 
)dt ) as mus_store_donations_ytd
,
(SELECT sum(dt.donations) 
FROM
(SELECT sum(f.Amount) as donations
FROM 911dw.fact_museum_ticketing_donations_issued f INNER JOIN 911dw.dim_date d ON f.key_date = d.date_key
WHERE f.key_museum_category = 3221
AND year(d.date_value) = year(${sameDateLastYear})
AND d.date_value<= ${sameDateLastYear}
UNION
select sum(mus_store_donations)
from fact_all_donations f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear}
)dt ) as mus_store_donations_ytd_py
,
(select sum(retail_cart_donations)
from fact_all_donations f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as cart_donations_ytd
,
(select sum(retail_cart_donations)
from fact_all_donations f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as cart_donations_ytd_py
,
(select sum(transactions)
from cafe_performance c 
inner join dim_date d on c.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as cafe_transactions_ytd
,
(select sum(transactions)
from cafe_performance c 
inner join dim_date d on c.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as cafe_transactions_ytd_py

,
(select sum(cafe_donations)
from fact_all_donations f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as cafe_donations_ytd
,
(select sum(cafe_donations)
from fact_all_donations f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as cafe_donations_ytd_py
,
(select cafe_revenue from fact_dpr_report_data f inner join dim_date d on f.key_date=d.date_key
where 
d.date_value = ${today}) as cafe_revenue
,
(select sum(cafe_revenue) from fact_dpr_report_data f inner join dim_date d on f.key_date=d.date_key
where year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today} ) as cafe_revenue_mtd
,
(select sum(cafe_revenue) from fact_dpr_report_data f inner join dim_date d on f.key_date=d.date_key
where d.year4=year(${today}) 
and d.date_value <= ${today} ) as cafe_revenue_ytd

,
(select sum(cafe_revenue) from fact_dpr_report_data f inner join dim_date d on f.key_date=d.date_key
where   year(d.date_value) = year(${sameDateLastYear})
and month(d.date_value)= month(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear}) as cafe_revenue_mtd_py
,
(select sum(cafe_revenue) from fact_dpr_report_data f inner join dim_date d on f.key_date=d.date_key
where   year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear}) as cafe_revenue_ytd_py
,
(select sum(shopify_donations)
from fact_all_donations f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as shopify_donations_ytd
,
(select sum(shopify_donations)
from fact_all_donations f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as shopify_donations_ytd_py

,
(select sum(est_operating_expenses) 
from fact_dpr_report_data f inner join dim_date d on f.key_date=d.date_key
where  year(d.date_value)=year(${today}) 
and d.date_value <= ${today}  ) as est_operating_expenses_ytd
,
(select sum(est_operating_expenses) 
from fact_dpr_report_data f inner join dim_date d on f.key_date=d.date_key
where  year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear}  ) as est_operating_expenses_ytd_py
,
(select sum(mus_field_trips)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as mus_field_trips_ytd
,
(select sum(mus_field_trips)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as mus_field_trips_ytd_py
,
(select sum(mus_field_trip_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as mus_field_trip_rev_ytd
,
(select sum(mus_field_trip_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as mus_field_trip_rev_ytd_py
,
(select sum(mem_field_trips)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as mem_field_trips_ytd
,
(select sum(mem_field_trips)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as mem_field_trips_ytd_py
,
(select sum(mem_field_trip_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as mem_field_trip_rev_ytd
,
(select sum(mem_field_trip_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear}) as mem_field_trip_rev_ytd_py
,
(select sum(virtual_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as virtual_mus_tours_ytd
,
(select sum(virtual_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as virtual_mus_tours_ytd_py
,
(select sum(virtual_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as virtual_mus_tour_rev_ytd
,
(select sum(virtual_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as virtual_mus_tour_rev_ytd_py
,
(select sum(mask_donations)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as mask_donations_ytd
,
(select sum(mask_donations)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as mask_donations_ytd_py
,
(select sum(ea_mem_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as ea_mem_mus_tours_ytd
,
(select sum(ea_mem_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as ea_mem_mus_tours_ytd_py
,
(select sum(ea_mem_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as ea_mem_mus_tour_revenue_ytd
,
(select sum(ea_mem_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear}) as ea_mem_mus_tour_revenue_ytd_py
,
(select sum(revealed_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as revealed_tour_revenue_ytd
,
(select sum(revealed_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear}) as revealed_tour_revenue_ytd_py
,
(select sum(ask_educator_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today})
and d.date_value <= ${today} ) as ask_educator_revenue_ytd
,
(select sum(ask_educator_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as ask_educator_revenue_ytd_py

,
(select sum(cafe1_profit_all)+sum(IFNULL(cafe_medallion_profit,0))
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND key_date <= ${today}) as cafe1_all_profit_ytd
,
(select sum(cafe1_profit_all)+sum(IFNULL(cafe_medallion_profit,0))
from  fact_retail_analysis
where year(key_date) = year(${sameDateLastYear})
and key_date <= ${sameDateLastYear}) as cafe1_all_profit_ytd_py
,
(select sum(cafe1_customers)
from  fact_retail_analysis
where year(key_date)= year(${today})
  and key_date <= ${today}) as cafe1_transactions_ytd
,
(select sum(cafe1_customers)
from  fact_retail_analysis
where year(key_date) = year(${sameDateLastYear})
and key_date <= ${sameDateLastYear}) as cafe1_transactions_ytd_py
,

(SELECT sum(cafe1_donations)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
and d.date_value <= ${today}) as cafe1_donations_ytd
,
(SELECT sum(cafe1_donations)
FROM fact_donations_analysis_report f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear}) as cafe1_donations_ytd_py
,
(select sum(mem_audio_tour_headset)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mem_audio_tour_headset_ytd
,
(select sum(mem_audio_tour_headset)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${sameDateLastYear})
and d.date_value<= ${sameDateLastYear} ) as mem_audio_tour_headset_ytd_py

-- ===== [datasources/sql-ds.xml] query: SameDateLastYear =====
select CONCAT(YEAR(${today})-1,DATE_FORMAT(${today},'-%m-%d')) as date_value