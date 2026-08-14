-- REPORT: Retail Performance Report (911dw.dayofdata.arialnormal)

-- ===== [datasources/sql-ds.xml] query: Master =====
SELECT
  (SELECT SUM(mus_store_visitors)
  FROM fact_retail_analysis
  where key_date = ${today})
  AS visitor_counted_mus_store
  ,
  (SELECT SUM(mus_store_visitors)
  FROM fact_retail_analysis
  where key_date = ${sameDayLastYear})
  AS visitor_counted_mus_store_sdly
 ,
 (SELECT SUM(mus_store_visitors)
  FROM fact_retail_analysis
 where year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  and key_date <= ${today})
  AS visitor_counted_mus_store_wtd
  ,
   (SELECT SUM(mus_store_visitors)
  FROM fact_retail_analysis
 where year(key_date)= year(${today})
  AND quarter(key_date)=quarter(${today})
  and key_date <= ${today})
  AS visitor_counted_mus_store_qtd
,
   (SELECT SUM(mus_store_visitors)
  FROM fact_retail_analysis
 where year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  and key_date <= ${today})
  AS visitor_counted_mus_store_mtd
  ,
   (SELECT SUM(mus_store_visitors)
  FROM fact_retail_analysis
 where year(key_date)= year(${today})
  and key_date <= ${today})
  AS visitor_counted_mus_store_ytd
  ,
(select sum(mus_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as mus_attendance
  ,
(select sum(mus_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${sameDayLastYear}) as mus_attendance_sdly
,
(select sum(mus_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as mus_attendance_mtd
,
(SELECT sum(mus_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) AS mus_attendance_wtd

,
(SELECT sum(mus_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and quarter(d.date_value)= quarter(${today})
and d.date_value<= ${today}) AS mus_attendance_qtd
,
(select sum(mus_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mus_attendance_ytd
,
(SELECT SUM(sales_mus_store)
  FROM fact_retail_analysis
  where key_date = ${today})
  AS sales_all_cat_mus_store
  ,
(SELECT SUM(sales_mus_store)
  FROM fact_retail_analysis
  where key_date = ${sameDayLastYear})
  AS sales_all_cat_mus_store_sdly
 ,
 (SELECT SUM(sales_mus_store)
  FROM fact_retail_analysis
 where year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  and key_date <= ${today})
  AS sales_all_cat_mus_store_wtd
   ,
 (SELECT SUM(sales_mus_store)
  FROM fact_retail_analysis
 where year(key_date)= year(${today})
  AND quarter(key_date)= quarter(${today})
  and key_date <= ${today})
  AS sales_all_cat_mus_store_qtd
  ,
 (SELECT SUM(sales_mus_store)
  FROM fact_retail_analysis
 where year(key_date)= year(${today})
  AND month(key_date)= month(${today})
  and key_date <= ${today})
  AS sales_all_cat_mus_store_mtd
  ,
 (SELECT SUM(sales_mus_store)
  FROM fact_retail_analysis
 where year(key_date)= year(${today})
  and key_date <= ${today})
  AS sales_all_cat_mus_store_ytd
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
AND d.date_value= ${today}) AS sales_all_cat_mus_store_budget
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
AND d.date_value= ${sameDayLastYear}) AS sales_all_cat_mus_store_budget_sdly
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) AS sales_all_cat_mus_store_budget_wtd
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) AS sales_all_cat_mus_store_budget_qtd
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) AS sales_all_cat_mus_store_budget_mtd
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) AS sales_all_cat_mus_store_budget_ytd
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
AND d.date_value=${today}) AS net_profit_mus_store_budget
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
AND d.date_value=${sameDayLastYear}) AS net_profit_mus_store_budget_sdly
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) AS net_profit_mus_store_budget_wtd

,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) AS net_profit_mus_store_budget_mtd
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) AS net_profit_mus_store_budget_qtd
 ,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) AS net_profit_mus_store_budget_ytd
 ,
 (SELECT SUM(mus_store_customers)
  FROM fact_retail_analysis
  where key_date = ${today})
  AS customers_mus_store
  ,
  (SELECT SUM(mus_store_customers)
  FROM fact_retail_analysis
  where key_date = ${sameDayLastYear})
  AS customers_mus_store_sdly
 ,
 (SELECT SUM(mus_store_customers)
  FROM fact_retail_analysis
 where year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  and key_date <= ${today})
  AS customers_mus_store_wtd
  ,
   (SELECT SUM(mus_store_customers)
  FROM fact_retail_analysis
 where year(key_date)= year(${today})
  AND quarter(key_date)=quarter(${today})
  and key_date <= ${today})
  AS customers_mus_store_qtd
,
   (SELECT SUM(mus_store_customers)
  FROM fact_retail_analysis
 where year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  and key_date <= ${today})
  AS customers_mus_store_mtd
  ,
   (SELECT SUM(mus_store_customers)
  FROM fact_retail_analysis
 where year(key_date)= year(${today})
  and key_date <= ${today})
  AS customers_mus_store_ytd

 ,
(SELECT sum(mus_store_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where d.date_value = ${today}) as sales_donate_mus_store 
,
(SELECT sum(mus_store_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where d.date_value = ${sameDayLastYear}) as sales_donate_mus_store_sdly
 ,
(SELECT sum(mus_store_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as sales_donate_mus_store_wtd
,
(SELECT sum(mus_store_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as sales_donate_mus_store_mtd
,
(SELECT sum(mus_store_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as sales_donate_mus_store_qtd
,
(SELECT sum(mus_store_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
and d.date_value <= ${today}) as sales_donate_mus_store_ytd
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
AND d.date_value=${today}) AS sales_donate_mus_store_budget
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
AND d.date_value=${sameDayLastYear}) AS sales_donate_mus_store_budget_sdly
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) AS sales_donate_mus_store_budget_wtd
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) AS sales_donate_mus_store_budget_qtd
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) AS sales_donate_mus_store_budget_mtd
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1003
AND year(d.date_value)= year(${today})
and d.date_value <= ${today}) AS sales_donate_mus_store_budget_ytd
,

(select sum(ecom_orders)
from  fact_retail_analysis
where key_date = ${today}) as ecom_total_orders
,
(select sum(ecom_orders)
from  fact_retail_analysis
where key_date = ${sameDayLastYear}) as ecom_total_orders_sdly
,
(select sum(ecom_orders)
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  and key_date <= ${today}) as ecom_total_orders_wtd
,
(select sum(ecom_orders)
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  and key_date <= ${today}) as ecom_total_orders_mtd
,
(select sum(ecom_orders)
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND quarter(key_date)= quarter(${today})
  and key_date <= ${today}) as ecom_total_orders_qtd
,
(select sum(ecom_orders)
from  fact_retail_analysis
where year(key_date)= year(${today})
    and key_date <= ${today}) as ecom_total_orders_ytd
,

(select sum(ecom_sales)
from  fact_retail_analysis
where key_date = ${today}) as ecom_all_sales
,
(select sum(ecom_sales)
from  fact_retail_analysis
where key_date = ${sameDayLastYear}) as ecom_all_sales_sdly
,
(select sum(ecom_sales)
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  and key_date <= ${today}) as ecom_all_sales_wtd
,
(select sum(ecom_sales)
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  and key_date <= ${today}) as ecom_all_sales_mtd
,
(select sum(ecom_sales)
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND quarter(key_date)= quarter(${today})
  and key_date <= ${today}) as ecom_all_sales_qtd
,
(select sum(ecom_sales)
from  fact_retail_analysis
where year(key_date)= year(${today})
    and key_date <= ${today}) as ecom_all_sales_ytd 

,
(select sum(cafe1_sales_all)
from  fact_retail_analysis
where key_date = ${today}) as cafe1_all_sales
,
(select sum(cafe1_sales_all)
from  fact_retail_analysis
where key_date = ${sameDayLastYear}) as cafe1_all_sales_sdly
,
(select sum(cafe1_sales_all)
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  and key_date <= ${today}) as cafe1_all_sales_wtd
,
(select sum(cafe1_sales_all)
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  and key_date <= ${today}) as cafe1_all_sales_mtd
,
(select sum(cafe1_sales_all)
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND quarter(key_date)= quarter(${today})
  and key_date <= ${today}) as cafe1_all_sales_qtd
,
(select sum(cafe1_sales_all)
from  fact_retail_analysis
where year(key_date)= year(${today})
    and key_date <= ${today}) as cafe1_all_sales_ytd 

,
(select sum(cafe1_profit_all)
from  fact_retail_analysis
where key_date = ${today}) as cafe1_all_profit
,
(select sum(cafe1_profit_all)
from  fact_retail_analysis
where key_date = ${sameDayLastYear}) as cafe1_all_profit_sdly
,
(select sum(cafe1_profit_all)
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  and key_date <= ${today}) as cafe1_all_profit_wtd
,
(select sum(cafe1_profit_all)
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  and key_date <= ${today}) as cafe1_all_profit_mtd
,
(select sum(cafe1_profit_all)
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND quarter(key_date)= quarter(${today})
  and key_date <= ${today}) as cafe1_all_profit_qtd
,
(select sum(cafe1_profit_all)
from  fact_retail_analysis
where year(key_date)= year(${today})
    and key_date <= ${today}) as cafe1_all_profit_ytd 

,
(select sum(cafe1_customers)
from  fact_retail_analysis
where key_date = ${today}) as cafe1_transactions
,
(select sum(cafe1_customers)
from  fact_retail_analysis
where key_date = ${sameDayLastYear}) as cafe1_transactions_sdly
,
(select sum(cafe1_customers)
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  and key_date <= ${today}) as cafe1_transactions_wtd
,
(select sum(cafe1_customers)
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  and key_date <= ${today}) as cafe1_transactions_mtd
,
(select sum(cafe1_customers)
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND quarter(key_date)= quarter(${today})
  and key_date <= ${today}) as cafe1_transactions_qtd
,
(select sum(cafe1_customers)
from  fact_retail_analysis
where year(key_date)= year(${today})
    and key_date <= ${today}) as cafe1_transactions_ytd 

,

(SELECT sum(cafe1_donations)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where d.date_value = ${today}) as cafe1_donations 
,
(SELECT sum(cafe1_donations)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where d.date_value = ${sameDayLastYear}) as cafe1_donations_sdly
 ,
(SELECT sum(cafe1_donations)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as cafe1_donations_wtd
,
(SELECT sum(cafe1_donations)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as cafe1_donations_mtd
,
(SELECT sum(cafe1_donations)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as cafe1_donations_qtd
,
(SELECT sum(cafe1_donations)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
and d.date_value <= ${today}) as cafe1_donations_ytd

,
(SELECT sum(retail_cart_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where d.date_value = ${today}) as sales_donate_mem_cart
,
(SELECT sum(retail_cart_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where d.date_value = ${sameDayLastYear}) as sales_donate_mem_cart_sdly
,
(SELECT sum(retail_cart_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as sales_donate_mem_cart_wtd
,
(SELECT sum(retail_cart_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as sales_donate_mem_cart_mtd
,
(SELECT sum(retail_cart_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as sales_donate_mem_cart_qtd
,
(SELECT sum(retail_cart_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
and d.date_value <= ${today}) as sales_donate_mem_cart_ytd
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on  r.key_date = d.date_key
where r.key_facility = 1020
AND d.date_value=${today}) as sales_donate_mem_cart_budget
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on  r.key_date = d.date_key
where r.key_facility = 1020
AND d.date_value=${sameDayLastYear}) as sales_donate_mem_cart_budget_sdly
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on  r.key_date = d.date_key
where r.key_facility = 1020
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as sales_donate_mem_cart_budget_wtd
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on  r.key_date = d.date_key
where r.key_facility = 1020
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as sales_donate_mem_cart_budget_mtd
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on  r.key_date = d.date_key
where r.key_facility = 1020
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as sales_donate_mem_cart_budget_qtd
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on  r.key_date = d.date_key
where r.key_facility = 1020
AND year(d.date_value)= year(${today})
and d.date_value <= ${today}) as sales_donate_mem_cart_budget_ytd
,
(SELECT sum(sales_mem_cart)
from fact_retail_analysis 
where key_date = ${today}) as sales_all_cat_mem_cart
,
(SELECT sum(sales_mem_cart)
from fact_retail_analysis 
where key_date = ${sameDayLastYear}) as sales_all_cat_mem_cart_sdly
,
(SELECT sum(sales_mem_cart)
from fact_retail_analysis 
where year(key_date)= year(${today})
AND weekofyear(key_date) = weekofyear(${today})
and key_date <= ${today}) as sales_all_cat_mem_cart_wtd
,
(SELECT sum(sales_mem_cart)
from fact_retail_analysis 
where year(key_date)= year(${today})
AND month(key_date) = month(${today})
and key_date <= ${today}) as sales_all_cat_mem_cart_mtd
,
(SELECT sum(sales_mem_cart)
from fact_retail_analysis 
where year(key_date)= year(${today})
AND quarter(key_date) = quarter(${today})
and key_date <= ${today}) as sales_all_cat_mem_cart_qtd
,
(SELECT sum(sales_mem_cart)
from fact_retail_analysis 
where year(key_date)= year(${today})
and key_date <= ${today}) as sales_all_cat_mem_cart_ytd
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1020
AND d.date_value=${today}) as sales_all_cat_mem_cart_budget 
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1020
AND d.date_value=${sameDayLastYear}) as sales_all_cat_mem_cart_budget_sdly
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1020
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as sales_all_cat_mem_cart_budget_wtd
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1020
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as sales_all_cat_mem_cart_budget_mtd
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1020
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as sales_all_cat_mem_cart_budget_qtd
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 1020
AND year(d.date_value)= year(${today})
and d.date_value <= ${today}) as sales_all_cat_mem_cart_budget_ytd
,
(select sum(vs_cart_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${today} ) as mem_donations
,
(select sum(vs_cart_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${sameDayLastYear} ) as mem_donations_sdly
,
(select sum(vs_cart_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)= year(${today})
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as mem_donations_wtd	
,
(select sum(vs_cart_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)= year(${today})
and month(d.date_value) = month(${today})
and d.date_value <= ${today}) as mem_donations_mtd
,
(select sum(vs_cart_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)= year(${today})
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as mem_donations_qtd
,
(select sum(vs_cart_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)= year(${today})
and d.date_value <= ${today}) as mem_donations_ytd
  ,
(select sum(mus_exit_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${today} ) as mus_exit_donations
,
(select sum(mus_exit_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${sameDayLastYear} ) as mus_exit_donations_sdly
,
(select sum(mus_exit_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)= year(${today})
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as mus_exit_donations_wtd	
,
(select sum(mus_exit_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)= year(${today})
and month(d.date_value) = month(${today})
and d.date_value <= ${today}) as mus_exit_donations_mtd
,
(select sum(mus_exit_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)= year(${today})
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as mus_exit_donations_qtd
,
(select sum(mus_exit_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)= year(${today})
and d.date_value <= ${today}) as mus_exit_donations_ytd
,
(SELECT sum(mem_cart_ask_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where d.date_value = ${today}) as mem_cart_don_ask
,
(SELECT sum(mem_cart_ask_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where d.date_value = ${sameDayLastYear}) as mem_cart_don_ask_sdly
,
(SELECT sum(mem_cart_ask_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as mem_cart_don_ask_wtd
,
(SELECT sum(mem_cart_ask_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as mem_cart_don_ask_mtd
,
(SELECT sum(mem_cart_ask_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as mem_cart_don_ask_qtd
,
(SELECT sum(mem_cart_ask_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
and d.date_value <= ${today}) as mem_cart_don_ask_ytd

,
(select sum(mus_plaza_box_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${today} ) as mus_plaza_box_donations
,
(select sum(mus_plaza_box_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${sameDayLastYear} ) as mus_plaza_box_donations_sdly
,
(select sum(mus_plaza_box_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)= year(${today})
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as mus_plaza_box_donations_wtd	
,
(select sum(mus_plaza_box_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)= year(${today})
and month(d.date_value) = month(${today})
and d.date_value <= ${today}) as mus_plaza_box_donations_mtd
,
(select sum(mus_plaza_box_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)= year(${today})
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as mus_plaza_box_donations_qtd
,
(select sum(mus_plaza_box_don) from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)= year(${today})
and d.date_value <= ${today}) as mus_plaza_box_donations_ytd

,
(select sum(mem_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as mem_attendance
  ,
(select sum(mem_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${sameDayLastYear}) as mem_attendance_sdly
,
(select sum(mem_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as mem_attendance_mtd
,
(SELECT sum(mem_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) AS mem_attendance_wtd

,
(SELECT sum(mem_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and quarter(d.date_value)= quarter(${today})
and d.date_value<= ${today}) AS mem_attendance_qtd
,
(select sum(mem_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mem_attendance_ytd
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on  r.key_date = d.date_key
where r.key_facility = 1020
AND d.date_value=${today}) as net_profit_mem_cart_budget
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on  r.key_date = d.date_key
where r.key_facility = 1020
AND d.date_value=${sameDayLastYear}) as net_profit_mem_cart_budget_sdly
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on  r.key_date = d.date_key
where r.key_facility = 1020
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as net_profit_mem_cart_budget_wtd
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on  r.key_date = d.date_key
where r.key_facility = 1020
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as net_profit_mem_cart_budget_mtd
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on  r.key_date = d.date_key
where r.key_facility = 1020
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as net_profit_mem_cart_budget_qtd
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on  r.key_date = d.date_key
where r.key_facility = 1020
AND year(d.date_value)= year(${today})
and d.date_value <= ${today}) as net_profit_mem_cart_budget_ytd


,
(SELECT SUM(mem_cart_customers)
FROM fact_retail_analysis
where key_date = ${today}) AS customers_mem_cart
,
(SELECT SUM(mem_cart_customers)
FROM fact_retail_analysis
where key_date = ${sameDayLastYear}) AS customers_mem_cart_sdly 
,
(SELECT SUM(mem_cart_customers)
FROM fact_retail_analysis
where  year(key_date)= year(${today})
AND weekofyear(key_date) = weekofyear(${today})
and key_date <= ${today}) AS customers_mem_cart_wtd
,
(SELECT SUM(mem_cart_customers)
FROM fact_retail_analysis
where  year(key_date)= year(${today})
and month(key_date) = month(${today})
and key_date <= ${today}) AS customers_mem_cart_mtd

  ,
(SELECT SUM(mem_cart_customers)
FROM fact_retail_analysis
where  year(key_date)= year(${today})
and quarter(key_date) = quarter(${today})
and key_date <= ${today}) AS customers_mem_cart_qtd
,
(SELECT SUM(mem_cart_customers)
FROM fact_retail_analysis
where  year(key_date)= year(${today})
and key_date <= ${today}) AS customers_mem_cart_ytd

,
(select customers from
fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1020
and d.date_value = ${today}) as customers_mem_cart_budget
,
(select customers from
fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1020
and d.date_value = ${sameDayLastYear}) as customers_mem_cart_budget_sdly
,
(select sum(customers) from
fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1020
and year(d.date_value)=year(${today}) 
and weekofyear(d.date_value)=weekofyear(${today})
and d.date_value <= ${today}) as customers_mem_cart_budget_wtd
,
(select sum(customers) from
fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1020
and year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today}) as customers_mem_cart_budget_mtd
,
(select sum(customers) from
fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1020
and year(d.date_value)=year(${today})
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as customers_mem_cart_budget_qtd
,
(select sum(customers) from
fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1020
and year(d.date_value)=year(${today})
and d.date_value <= ${today}) as customers_mem_cart_budget_ytd

,
(select visitors 
from fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1003
and d.date_value = ${today}) as visitor_counted_mus_store_budget
,
(select visitors 
from fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1003
and d.date_value = ${sameDayLastYear}) as visitor_counted_mus_store_budget_sdly
,
(select sum(visitors) 
from fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)=year(${today}) 
and weekofyear(d.date_value)= weekofyear(${today})
and d.date_value <= ${today}) as visitor_counted_mus_store_budget_wtd
,
(select sum(visitors) 
from fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today}) as visitor_counted_mus_store_budget_mtd
,
(select sum(visitors )
from fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1003
and year(d.date_value)=year(${today})
and quarter(d.date_value)= quarter(${today})
and d.date_value <= ${today}) as visitor_counted_mus_store_budget_qtd
,
(select sum(visitors )
from fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1003
and year(d.date_value)=year(${today})
and d.date_value <= ${today}) as visitor_counted_mus_store_budget_ytd
,
(select new_attendance 
from fact_forecasted_value_for_date f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility =1003
and d.date_value = ${today}) as mus_attendance_budget
,
(select new_attendance 
from fact_forecasted_value_for_date f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility =1003
and d.date_value = ${sameDayLastYear}) as mus_attendance_budget_sdly
,
(select sum(new_attendance) 
from fact_forecasted_value_for_date f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility =1003
and year(d.date_value)=year(${today}) 
and weekofyear(d.date_value)= weekofyear(${today})
and d.date_value <= ${today}) as mus_attendance_budget_wtd
,
(select sum(new_attendance) 
from fact_forecasted_value_for_date f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility =1003
and year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today}) as mus_attendance_budget_mtd
,
(select sum(new_attendance )
from fact_forecasted_value_for_date f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility =1003
and year(d.date_value)=year(${today})
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as mus_attendance_budget_qtd
,
(select sum(new_attendance )
from fact_forecasted_value_for_date f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility =1003
and year(d.date_value)=year(${today})
and d.date_value <= ${today}) as mus_attendance_budget_ytd
,
(select customers 
from fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1003
and d.date_value = ${today}) as customers_mus_store_budget
,
(select customers 
from fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1003
and d.date_value = ${sameDayLastYear}) as customers_mus_store_budget_sdly
,
(select sum(customers) 
from fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1003
and year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as customers_mus_store_budget_wtd
,
(select sum(customers) 
from fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1003
and year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today}) as customers_mus_store_budget_mtd
,
(select sum(customers )
from fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1003
and year(d.date_value)=year(${today})
and quarter(d.date_value)= quarter(${today})
and d.date_value <= ${today}) as customers_mus_store_budget_qtd
,
(select sum(customers )
from fact_retail_forecasts f inner join dim_date d
on f.key_date=d.date_key
where f.key_facility=1003
and year(d.date_value)=year(${today})
and d.date_value <= ${today}) as customers_mus_store_budget_ytd
,
(select profit_from_ecom
from fact_dpr_forecasts f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${today}) as net_profit_ecom_budget
,
(select profit_from_ecom
from fact_dpr_forecasts f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${sameDayLastYear}) as net_profit_ecom_budget_sdly

,
(select sum(profit_from_ecom)
from fact_dpr_forecasts f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)=year(${today}) 
and weekofyear(d.date_value)= weekofyear(${today})
and d.date_value <= ${today}) as net_profit_ecom_budget_wtd
,
(select sum(profit_from_ecom)
from fact_dpr_forecasts f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today}) as net_profit_ecom_budget_mtd
,
(select sum(profit_from_ecom)
from fact_dpr_forecasts f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)=year(${today})
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as net_profit_ecom_budget_qtd
,
(select sum(profit_from_ecom)
from fact_dpr_forecasts f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)=year(${today})
and d.date_value <= ${today}) as net_profit_ecom_budget_ytd
,
(select museum_exit_donations
from fact_dpr_forecasts f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${today}) as mus_exit_donations_budget
,
(select museum_exit_donations
from fact_dpr_forecasts f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${sameDayLastYear}) as mus_exit_donations_budget_sdly
,
(select sum(museum_exit_donations)
from fact_dpr_forecasts f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as mus_exit_donations_budget_wtd
,
(select sum(museum_exit_donations)
from fact_dpr_forecasts f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today}) as mus_exit_donations_budget_mtd
,
(select sum(museum_exit_donations)
from fact_dpr_forecasts f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)=year(${today})
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as mus_exit_donations_budget_qtd
,
(select sum(museum_exit_donations)
from fact_dpr_forecasts f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value)=year(${today})
and d.date_value <= ${today}) as mus_exit_donations_budget_ytd
,
(select profit_from_ecom
from fact_dpr_forecasts f inner join dim_date d
on f.key_date= d.date_key
where d.date_value = ${today}) as total_net_profit_ecom_budget
,
(select profit_from_ecom
from fact_dpr_forecasts f inner join dim_date d
on f.key_date= d.date_key
where  d.date_value = ${sameDayLastYear}) as total_net_profit_ecom_sdly_budget
,
(select sum(profit_from_ecom)
from fact_dpr_forecasts f inner join dim_date d
on f.key_date= d.date_key
where  year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as total_net_profit_ecom_wtd_budget 
,
(select sum(profit_from_ecom)
from fact_dpr_forecasts f inner join dim_date d
on f.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <=${today}) as total_net_profit_ecom_mtd_budget
,
(select sum(profit_from_ecom)
from fact_dpr_forecasts f inner join dim_date d
on f.key_date= d.date_key
where year(d.date_value)=year(${today})
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as total_net_profit_ecom_qtd_budget
,
(select sum(profit_from_ecom)
from fact_dpr_forecasts f inner join dim_date d
on f.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.date_value <=${today}) as total_net_profit_ecom_ytd_budget
,
(select average_sale 
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where  f.key_facility=1003
and d.date_value = ${today}) as mus_store_avg_daily_sale_budget
,
(select average_sale 
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where  f.key_facility=1003
and d.date_value = ${sameDayLastYear}) as mus_store_avg_daily_sale_budget_sdly
,
(select AVG(average_sale) 
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where  f.key_facility=1003
and year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as mus_store_avg_daily_sale_budget_wtd
,
(select AVG(average_sale) 
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where  f.key_facility=1003
and year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today}) as mus_store_avg_daily_sale_budget_mtd
,
(select AVG(average_sale) 
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where  f.key_facility=1003
and year(d.date_value)=year(${today})
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as mus_store_avg_daily_sale_budget_qtd
,
(select AVG(average_sale) 
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where f.key_facility=1003
and year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as mus_store_avg_daily_sale_budget_ytd

,
(select revenue from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where  d.date_value = ${today}) as cafe_revenue_today
,
(select revenue from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where  d.date_value = ${sameDayLastYear}) as cafe_revenue_sdly
,
(select sum(revenue) from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where  year(d.date_value) = year(${sameDayLastYear})
and d.date_value <= ${sameDayLastYear}) as cafe_revenue_sdly_ytd
,
(select sum(revenue) from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as cafe_revenue_wtd
,
(select sum(revenue) from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where  year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today} ) as cafe_revenue_mtd
,
(select sum(revenue) from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where  year(d.date_value)=year(${today})
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as cafe_revenue_qtd
,
(select sum(revenue) from cafe_performance c  inner join dim_date d
on c.key_date= d.date_key
where  d.year4=year(${today}) 
and d.date_value <= ${today} ) as cafe_revenue_ytd
,
(select transactions from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where d.date_value = ${today}) as cafe_trans_today
,
(select transactions from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where d.date_value = ${sameDayLastYear}) as cafe_trans_sdly

,
(select sum(transactions) from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as cafe_trans_wtd
,
(select sum(transactions) from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where  year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today} ) as cafe_trans_mtd
,
(select sum(transactions) from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where  year(d.date_value)=year(${today})
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as cafe_trans_qtd
,
(select sum(transactions) from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where  d.year4=year(${today}) 
and d.date_value <= ${today} ) as cafe_trans_ytd
,
(select average_sale from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where  f.key_facility = 1020
and d.date_value = ${today}) as AvgSaleMemCart_budget
,
(select average_sale 
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where f.key_facility=1020
and d.date_value = ${sameDayLastYear}) as AvgSaleMemCart_budget_sdly
,
(select AVG(average_sale) 
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where f.key_facility=1020
and year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as AvgSaleMemCart_budget_wtd
,
(select AVG(average_sale) 
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where f.key_facility=1020
and year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today}) as AvgSaleMemCart_budget_mtd
,
(select AVG(average_sale) 
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where f.key_facility=1020
and year(d.date_value)=year(${today})
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as AvgSaleMemCart_budget_qtd
,
(select AVG(average_sale) 
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where  f.key_facility=1020
and year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as AvgSaleMemCart_budget_ytd
,
(select donations from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where  d.date_value = ${today}) as cafe_donations_today
,
(select donations from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where d.date_value = ${sameDayLastYear}) as cafe_donations_sdly

,
(select sum(donations) from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where  year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as cafe_donations_wtd
,
(select sum(donations) from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today} ) as cafe_donations_mtd
,
(select sum(donations) from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where  year(d.date_value)=year(${today})
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as cafe_donations_qtd
,
(select sum(donations) from cafe_performance c inner join dim_date d
on c.key_date= d.date_key
where  d.year4=year(${today}) 
and d.date_value <= ${today} ) as cafe_donations_ytd
,
(select sum(Amount) from fact_retail f inner join dim_date d
on f.key_date= d.date_key
where f.key_summary_category = 6
and f.key_facility = 1234
and d.date_value = ${today}) as ecom_donations
,
(select sum(Amount) from fact_retail f inner join dim_date d
on f.key_date= d.date_key
where f.key_summary_category = 6
and f.key_facility = 1234
and d.date_value = ${sameDayLastYear}) as ecom_donations_sdly
,
(select sum(Amount) from fact_retail f inner join dim_date d
on f.key_date= d.date_key
where  f.key_summary_category = 6
and f.key_facility = 1234
and year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as ecom_donations_wtd
,
(select sum(Amount) from fact_retail f inner join dim_date d
on f.key_date= d.date_key
where f.key_summary_category = 6
and f.key_facility = 1234
and d.year4=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today} ) as ecom_donations_mtd
,

(select sum(Amount) from fact_retail f inner join dim_date d
on f.key_date= d.date_key
where  f.key_summary_category = 6
and f.key_facility = 1234
and year(d.date_value)=year(${today})
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as ecom_donations_qtd
,
(select sum(Amount) from fact_retail f inner join dim_date d
on f.key_date= d.date_key
where f.key_summary_category = 6
and f.key_facility = 1234
and d.year4=year(${today}) 
and d.date_value <= ${today} ) as ecom_donations_ytd
,
(select sum(mus_store_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where d.date_value = ${today}) as net_profit_mus_store
,
(select sum(mus_store_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where d.date_value = ${sameDayLastYear}) as net_profit_mus_store_sdly
,
(select sum(mus_store_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as net_profit_mus_store_wtd
,
(select sum(mus_store_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)=year(${today}) 
and month(d.date_value) = month(${today})
and d.date_value <= ${today}) as net_profit_mus_store_mtd
,
(select sum(mus_store_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)=year(${today}) 
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as net_profit_mus_store_qtd
,
(select sum(mus_store_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as net_profit_mus_store_ytd
,
(select sum(retail_carts_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where d.date_value = ${today}) as net_profit_mem_cart
,
(select sum(retail_carts_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where d.date_value = ${sameDayLastYear}) as net_profit_mem_cart_sdly
,
(select sum(retail_carts_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as net_profit_mem_cart_wtd
,
(select sum(retail_carts_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)=year(${today}) 
and month(d.date_value) = month(${today})
and d.date_value <= ${today}) as net_profit_mem_cart_mtd
,
(select sum(retail_carts_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)=year(${today}) 
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as net_profit_mem_cart_qtd
,
(select sum(retail_carts_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as net_profit_mem_cart_ytd
,
(select sum(ecom_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where d.date_value = ${today}) as net_profit_ecom
,
(select sum(ecom_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where d.date_value = ${sameDayLastYear}) as net_profit_ecom_sdly
,
(select sum(ecom_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as net_profit_ecom_wtd
,
(select sum(ecom_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)=year(${today}) 
and month(d.date_value) = month(${today})
and d.date_value <= ${today}) as net_profit_ecom_mtd
,
(select sum(ecom_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)=year(${today}) 
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as net_profit_ecom_qtd
,
(select sum(ecom_gross_profit) 
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as net_profit_ecom_ytd
, 
(select sum(Amount +Return_Amount)
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and f.key_summary_category = 13
and d.date_value = ${today}) as atrium_sales
, 
(select sum(Amount +Return_Amount)
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and f.key_summary_category = 13
and d.date_value = ${sameDayLastYear}) as atrium_sales_sdly
, 
(select sum(Amount +Return_Amount)
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and f.key_summary_category = 13
and year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as atrium_sales_wtd
, 
(select sum(Amount +Return_Amount)
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and f.key_summary_category = 13
and year(d.date_value)=year(${today}) 
and month(d.date_value) = month(${today})
and d.date_value <= ${today}) as atrium_sales_mtd
, 
(select sum(Amount +Return_Amount)
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and f.key_summary_category = 13
and year(d.date_value)=year(${today}) 
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as atrium_sales_qtd
, 
(select sum(Amount +Return_Amount)
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and f.key_summary_category = 13
and year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as atrium_sales_ytd
, 
(select sum(Amount +Return_Amount)
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and f.key_summary_category = 6
and d.date_value = ${today}) as donations_atrium
, 
(select sum(Amount +Return_Amount)
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and f.key_summary_category = 6
and d.date_value = ${sameDayLastYear}) as donations_atrium_sdly
, 
(select sum(Amount +Return_Amount)
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and f.key_summary_category = 6
and year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as donations_atrium_wtd
, 
(select sum(Amount +Return_Amount)
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and f.key_summary_category = 6
and year(d.date_value)=year(${today}) 
and month(d.date_value) = month(${today})
and d.date_value <= ${today}) as donations_atrium_mtd
, 
(select sum(Amount +Return_Amount)
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and f.key_summary_category = 6
and year(d.date_value)=year(${today}) 
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as donations_atrium_qtd
, 
(select sum(Amount +Return_Amount)
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and f.key_summary_category = 6
and year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as donations_atrium_ytd
, 
(select sum(Cost)
from fact_cogs f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and d.date_value = ${today}) as atrium_cost
, 
(select sum(Cost)
from fact_cogs f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and d.date_value = ${sameDayLastYear}) as atrium_cost_sdly
, 
(select sum(Cost)
from fact_cogs f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as atrium_cost_wtd
, 
(select sum(Cost)
from fact_cogs f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and year(d.date_value)=year(${today}) 
and month(d.date_value) = month(${today})
and d.date_value <= ${today}) as atrium_cost_mtd
, 
(select sum(Cost)
from fact_cogs f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and year(d.date_value)=year(${today}) 
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as atrium_cost_qtd
, 
(select sum(Cost)
from fact_cogs f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as atrium_cost_ytd
, 
(select sum(num_tickets)
from fact_num_tickets f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and d.date_value = ${today}) as customers_atrium
, 
(select sum(num_tickets)
from fact_num_tickets f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and d.date_value = ${sameDayLastYear}) as customers_atrium_sdly
, 
(select sum(num_tickets)
from fact_num_tickets f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as customers_atrium_wtd
, 
(select sum(num_tickets)
from fact_num_tickets f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and year(d.date_value)=year(${today}) 
and month(d.date_value) = month(${today})
and d.date_value <= ${today}) as customers_atrium_mtd
, 
(select sum(num_tickets)
from fact_num_tickets f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and year(d.date_value)=year(${today}) 
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as customers_atrium_qtd
, 
(select sum(num_tickets)
from fact_num_tickets f inner join dim_date d
on f.key_date = d.date_key
where f.key_facility = 1030
and year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as customers_atrium_ytd
,
(select capture_rate 
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where  f.key_facility = 1003
and d.date_value = ${today}) as capRate_budget
,
(select capture_rate
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where f.key_facility=1003
and d.date_value = ${sameDayLastYear}) as capRate_budget_sdly
,
(select avg(capture_rate)
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where f.key_facility=1003
and year(d.date_value)=year(${today}) 
and weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as capRate_budget_wtd
,
(select avg(capture_rate)
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where f.key_facility=1003
and year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today}) as capRate_budget_mtd
,
(select avg(capture_rate)
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where f.key_facility=1003
and year(d.date_value)=year(${today})
and quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as capRate_budget_qtd
,
(select avg(capture_rate) 
from fact_retail_forecasts f inner join dim_date d
on f.key_date= d.date_key
where  f.key_facility=1003
and year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as capRate_budget_ytd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1003
and d.date_value = ${today} ) as nff_mus_store_today
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1003
and d.date_value = ${sameDayLastYear}) as nff_mus_store_sdly
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1003
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as nff_mus_store_wtd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1003
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as nff_mus_store_mtd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1003
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as nff_mus_store_qtd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1003
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as nff_mus_store_ytd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1020
and d.date_value = ${today} ) as nff_carts_today
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1020
and d.date_value = ${sameDayLastYear}) as nff_carts_sdly
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1020
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as nff_carts_wtd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1020
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as nff_carts_mtd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1020
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as nff_carts_qtd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1020
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as nff_carts_ytd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1234
and d.date_value = ${today} ) as nff_ecom_today
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1234
and d.date_value = ${sameDayLastYear}) as nff_ecom_sdly
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1234
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as nff_ecom_wtd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1234
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as nff_ecom_mtd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1234
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as nff_ecom_qtd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4637
and f.key_facility =1234
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as nff_ecom_ytd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4671
and d.date_value = ${today} ) as free_nff_units
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4671
and d.date_value = ${sameDayLastYear}) as free_nff_units_sdly
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4671
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as free_nff_units_wtd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4671
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as free_nff_units_mtd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4671
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as free_nff_units_qtd
,
(select sum(QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr=4671
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as free_nff_units_ytd
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
AND d.date_value=${today}) AS cafe1_revenue_budget
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
AND d.date_value=${sameDayLastYear}) AS cafe1_revenue_budget_sdly
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) AS cafe1_revenue_budget_wtd
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) AS cafe1_revenue_budget_mtd
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) AS cafe1_revenue_budget_qtd
,
(SELECT SUM(revenue)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) AS cafe1_revenue_budget_ytd
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
AND d.date_value=${today}) AS cafe1_donations_budget
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
AND d.date_value=${sameDayLastYear}) AS cafe1_donations_budget_sdly
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) AS cafe1_donations_budget_wtd
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) AS cafe1_donations_budget_mtd
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) AS cafe1_donations_budget_qtd
,
(SELECT SUM(donations)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) AS cafe1_donations_budget_ytd
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
AND d.date_value=${today}) AS cafe1_profit_budget
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
AND d.date_value=${sameDayLastYear}) AS cafe1_profit_budget_sdly
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) AS cafe1_profit_budget_wtd
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) AS cafe1_profit_budget_mtd
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) AS cafe1_profit_budget_qtd
,
(SELECT SUM(profit_from_retail)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) AS cafe1_profit_budget_ytd
,

(SELECT SUM(customers)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
AND d.date_value=${today}) AS cafe1_customers_budget
,
(SELECT SUM(customers)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
AND d.date_value=${sameDayLastYear}) AS cafe1_customers_budget_sdly
,
(SELECT SUM(customers)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) AS cafe1_customers_budget_wtd
,
(SELECT SUM(customers)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) AS cafe1_customers_budget_mtd
,
(SELECT SUM(customers)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) AS cafe1_customers_budget_qtd
,
(SELECT SUM(customers)
FROM 911dw.fact_retail_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
where r.key_facility = 4007
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) AS cafe1_customers_budget_ytd

,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr='3353'
and d.date_value = ${today} ) as total_flown_flag_units
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr='3353'
and d.date_value = ${sameDayLastYear}) as total_flown_flag_units_sdly
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr='3353'
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as total_flown_flag_units_wtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr='3353'
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as total_flown_flag_units_mtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr='3353'
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as total_flown_flag_units_qtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr='3353'
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as total_flown_flag_units_ytd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_item_descr = '3353'
AND d.date_value = ${today}
GROUP BY f.key_item_descr
)d) as total_flown_flag_profit
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_item_descr = '3353'
AND d.date_value = ${sameDayLastYear}
GROUP BY f.key_item_descr
)d) as total_flown_flag_profit_sdly
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_item_descr = '3353'
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_flown_flag_profit_wtd
,

(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_item_descr = '3353'
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_flown_flag_profit_mtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_item_descr = '3353'
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_flown_flag_profit_qtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_item_descr = '3353'
AND year(d.date_value)= year(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_flown_flag_profit_ytd

,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr in ('4636','5095')
and d.date_value = ${today} ) as total_water_units
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr in ('4636','5095')
and d.date_value = ${sameDayLastYear}) as total_water_units_sdly
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr in ('4636','5095')
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as total_water_units_wtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr in ('4636','5095')
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as total_water_units_mtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr in ('4636','5095')
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as total_water_units_qtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_item_descr in ('4636','5095')
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as total_water_units_ytd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_item_descr in ('4636','5095')
AND d.date_value = ${today}
GROUP BY f.key_item_descr
)d) as total_water_profit
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_item_descr in ('4636','5095')
AND d.date_value = ${sameDayLastYear}
GROUP BY f.key_item_descr
)d) as total_water_profit_sdly
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_item_descr in ('4636','5095')
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_water_profit_wtd
,

(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_item_descr in ('4636','5095')
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_water_profit_mtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_item_descr in ('4636','5095')
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_water_profit_qtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_item_descr in ('4636','5095')
AND year(d.date_value)= year(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_water_profit_ytd

,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='22'
and d.date_value = ${today} ) as total_tshirts_units
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='22'
and d.date_value = ${sameDayLastYear}) as total_tshirts_units_sdly
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='22'
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as total_tshirts_units_wtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='22'
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as total_tshirts_units_mtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='22'
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as total_tshirts_units_qtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='22'
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as total_tshirts_units_ytd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '22'
AND d.date_value = ${today}
GROUP BY f.key_item_descr
)d) as total_tshirts_profit
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '22'
AND d.date_value = ${sameDayLastYear}
GROUP BY f.key_item_descr
)d) as total_tshirts_profit_sdly
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '22'
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_tshirts_profit_wtd
,

(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '22'
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_tshirts_profit_mtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '22'
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_tshirts_profit_qtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '22'
AND year(d.date_value)= year(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_tshirts_profit_ytd

,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2659'
and d.date_value = ${today} ) as total_hoodie_units
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2659'
and d.date_value = ${sameDayLastYear}) as total_hoodie_units_sdly
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2659'
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as total_hoodie_units_wtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2659'
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as total_hoodie_units_mtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2659'
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as total_hoodie_units_qtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2659'
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as total_hoodie_units_ytd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2659'
AND d.date_value = ${today}
GROUP BY f.key_item_descr
)d) as total_hoodie_profit
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2659'
AND d.date_value = ${sameDayLastYear}
GROUP BY f.key_item_descr
)d) as total_hoodie_profit_sdly
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2659'
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_hoodie_profit_wtd
,

(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2659'
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_hoodie_profit_mtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2659'
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_hoodie_profit_qtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2659'
AND year(d.date_value)= year(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_hoodie_profit_ytd

,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2282'
and d.date_value = ${today} ) as total_hats_units
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2282'
and d.date_value = ${sameDayLastYear}) as total_hats_units_sdly
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2282'
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as total_hats_units_wtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2282'
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as total_hats_units_mtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2282'
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as total_hats_units_qtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2282'
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as total_hats_units_ytd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2282'
AND d.date_value = ${today}
GROUP BY f.key_item_descr
)d) as total_hats_profit
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2282'
AND d.date_value = ${sameDayLastYear}
GROUP BY f.key_item_descr
)d) as total_hats_profit_sdly
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2282'
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_hats_profit_wtd
,

(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2282'
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_hats_profit_mtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2282'
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_hats_profit_qtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2282'
AND year(d.date_value)= year(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_hats_profit_ytd

,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='20'
and d.date_value = ${today} ) as total_keychains_units
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='20'
and d.date_value = ${sameDayLastYear}) as total_keychains_units_sdly
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='20'
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as total_keychains_units_wtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='20'
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as total_keychains_units_mtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='20'
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as total_keychains_units_qtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='20'
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as total_keychains_units_ytd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '20'
AND d.date_value = ${today}
GROUP BY f.key_item_descr
)d) as total_keychains_profit
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '20'
AND d.date_value = ${sameDayLastYear}
GROUP BY f.key_item_descr
)d) as total_keychains_profit_sdly
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '20'
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_keychains_profit_wtd
,

(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '20'
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_keychains_profit_mtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '20'
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_keychains_profit_qtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '20'
AND year(d.date_value)= year(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_keychains_profit_ytd

,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='6'
and d.date_value = ${today} ) as total_magnets_units
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='6'
and d.date_value = ${sameDayLastYear}) as total_magnets_units_sdly
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='6'
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as total_magnets_units_wtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='6'
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as total_magnets_units_mtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='6'
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as total_magnets_units_qtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='6'
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as total_magnets_units_ytd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '6'
AND d.date_value = ${today}
GROUP BY f.key_item_descr
)d) as total_magnets_profit
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '6'
AND d.date_value = ${sameDayLastYear}
GROUP BY f.key_item_descr
)d) as total_magnets_profit_sdly
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '6'
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_magnets_profit_wtd
,

(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '6'
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_magnets_profit_mtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '6'
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_magnets_profit_qtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '6'
AND year(d.date_value)= year(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_magnets_profit_ytd

,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2280'
and d.date_value = ${today} ) as total_drinkware_units
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2280'
and d.date_value = ${sameDayLastYear}) as total_drinkware_units_sdly
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2280'
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as total_drinkware_units_wtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2280'
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as total_drinkware_units_mtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2280'
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as total_drinkware_units_qtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='2280'
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as total_drinkware_units_ytd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2280'
AND d.date_value = ${today}
GROUP BY f.key_item_descr
)d) as total_drinkware_profit
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2280'
AND d.date_value = ${sameDayLastYear}
GROUP BY f.key_item_descr
)d) as total_drinkware_profit_sdly
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2280'
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_drinkware_profit_wtd
,

(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2280'
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_drinkware_profit_mtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2280'
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_drinkware_profit_qtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '2280'
AND year(d.date_value)= year(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_drinkware_profit_ytd

,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='16'
and d.date_value = ${today} ) as total_totes_units
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='16'
and d.date_value = ${sameDayLastYear}) as total_totes_units_sdly
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='16'
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as total_totes_units_wtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='16'
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as total_totes_units_mtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='16'
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as total_totes_units_qtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='16'
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as total_totes_units_ytd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '16'
AND d.date_value = ${today}
GROUP BY f.key_item_descr
)d) as total_totes_profit
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '16'
AND d.date_value = ${sameDayLastYear}
GROUP BY f.key_item_descr
)d) as total_totes_profit_sdly
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '16'
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_totes_profit_wtd
,

(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '16'
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_totes_profit_mtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '16'
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_totes_profit_qtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '16'
AND year(d.date_value)= year(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_totes_profit_ytd

,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='4267'
and d.date_value = ${today} ) as total_food_units
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='4267'
and d.date_value = ${sameDayLastYear}) as total_food_units_sdly
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='4267'
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as total_food_units_wtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='4267'
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as total_food_units_mtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='4267'
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as total_food_units_qtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='4267'
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as total_food_units_ytd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '4267'
AND d.date_value = ${today}
GROUP BY f.key_item_descr
)d) as total_food_profit
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '4267'
AND d.date_value = ${sameDayLastYear}
GROUP BY f.key_item_descr
)d) as total_food_profit_sdly
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '4267'
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_food_profit_wtd
,

(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '4267'
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_food_profit_mtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '4267'
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_food_profit_qtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category  = '4267'
AND year(d.date_value)= year(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_food_profit_ytd

,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='4279' and f.key_item_descr NOT IN ('4828','5120','4880')
and d.date_value = ${today} ) as total_beverage_units
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='4279' and f.key_item_descr NOT IN ('4828','5120','4880')
and d.date_value = ${sameDayLastYear}) as total_beverage_units_sdly
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='4279' and f.key_item_descr NOT IN ('4828','5120','4880')
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as total_beverage_units_wtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='4279' and f.key_item_descr NOT IN ('4828','5120','4880')
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as total_beverage_units_mtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='4279' and f.key_item_descr NOT IN ('4828','5120','4880')
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as total_beverage_units_qtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
where f.key_sub_category='4279' and f.key_item_descr NOT IN ('4828','5120','4880')
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as total_beverage_units_ytd
,

(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category='4279' and f.key_item_descr NOT IN ('4828','5120','4880')
AND d.date_value = ${today}
GROUP BY f.key_item_descr
)d) as total_beverage_profit
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category='4279' and f.key_item_descr NOT IN ('4828','5120','4880')
AND d.date_value = ${sameDayLastYear}
GROUP BY f.key_item_descr
)d) as total_beverage_profit_sdly
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category='4279' and f.key_item_descr NOT IN ('4828','5120','4880')
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_beverage_profit_wtd
,

(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category='4279' and f.key_item_descr NOT IN ('4828','5120','4880')
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_beverage_profit_mtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category='4279' and f.key_item_descr NOT IN ('4828','5120','4880')
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_beverage_profit_qtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE f.key_sub_category='4279' and f.key_item_descr NOT IN ('4828','5120','4880')
AND year(d.date_value)= year(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_beverage_profit_ytd

,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
WHERE (
f.key_sub_category IN ( '4339') OR
f.key_item_descr IN
(select '4687' union
 select key_item_desc from dim_item_descr
 where item_desc like '%bracelet%' and item_desc like '%rubber%' and key_item_desc is not null
)
)
and d.date_value = ${today} ) as total_rubber_bracelet_units
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
WHERE (
f.key_sub_category IN ( '4339') OR
f.key_item_descr IN
(select '4687' union
 select key_item_desc from dim_item_descr
 where item_desc like '%bracelet%' and item_desc like '%rubber%' and key_item_desc is not null
)
)
and d.date_value = ${sameDayLastYear}) as total_rubber_bracelet_units_sdly
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
WHERE (
f.key_sub_category IN ( '4339') OR
f.key_item_descr IN
(select '4687' union
 select key_item_desc from dim_item_descr
 where item_desc like '%bracelet%' and item_desc like '%rubber%' and key_item_desc is not null
)
)
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as total_rubber_bracelet_units_wtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
WHERE (
f.key_sub_category IN ( '4339') OR
f.key_item_descr IN
(select '4687' union
 select key_item_desc from dim_item_descr
 where item_desc like '%bracelet%' and item_desc like '%rubber%' and key_item_desc is not null
)
)
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) as total_rubber_bracelet_units_mtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
WHERE (
f.key_sub_category IN ( '4339') OR
f.key_item_descr IN
(select '4687' union
 select key_item_desc from dim_item_descr
 where item_desc like '%bracelet%' and item_desc like '%rubber%' and key_item_desc is not null
)
)
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as total_rubber_bracelet_units_qtd
,
(select sum(f.QTY)+sum(f.Return_QTY) 
from fact_retail f inner join dim_date d
on f.key_date = d.date_key
WHERE (
f.key_sub_category IN ( '4339') OR
f.key_item_descr IN
(select '4687' union
 select key_item_desc from dim_item_descr
 where item_desc like '%bracelet%' and item_desc like '%rubber%' and key_item_desc is not null
)
)
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as total_rubber_bracelet_units_ytd
,

(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE (
f.key_sub_category IN ( '4339') OR
f.key_item_descr IN
(select '4687' union
 select key_item_desc from dim_item_descr
 where item_desc like '%bracelet%' and item_desc like '%rubber%' and key_item_desc is not null
)
)
AND d.date_value = ${today}
GROUP BY f.key_item_descr
)d) as total_rubber_bracelet_profit
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE (
f.key_sub_category IN ( '4339') OR
f.key_item_descr IN
(select '4687' union
 select key_item_desc from dim_item_descr
 where item_desc like '%bracelet%' and item_desc like '%rubber%' and key_item_desc is not null
)
)
AND d.date_value = ${sameDayLastYear}
GROUP BY f.key_item_descr
)d) as total_rubber_bracelet_profit_sdly
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE (
f.key_sub_category IN ( '4339') OR
f.key_item_descr IN
(select '4687' union
 select key_item_desc from dim_item_descr
 where item_desc like '%bracelet%' and item_desc like '%rubber%' and key_item_desc is not null
)
)
AND year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_rubber_bracelet_profit_wtd
,

(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE (
f.key_sub_category IN ( '4339') OR
f.key_item_descr IN
(select '4687' union
 select key_item_desc from dim_item_descr
 where item_desc like '%bracelet%' and item_desc like '%rubber%' and key_item_desc is not null
)
)
AND year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_rubber_bracelet_profit_mtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE (
f.key_sub_category IN ( '4339') OR
f.key_item_descr IN
(select '4687' union
 select key_item_desc from dim_item_descr
 where item_desc like '%bracelet%' and item_desc like '%rubber%' and key_item_desc is not null
)
)
AND year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_rubber_bracelet_profit_qtd
,
(SELECT 
    (SUM(d.Amount)+SUM(d.Return_Amount))-SUM(d.COST)-SUM(d.CostPI)
FROM 
(
SELECT sum(f.QTY) as Qty, sum(f.Amount) as Amount, sum(f.COST) as Cost,
       sum(f.Return_QTY) as Return_QTY, sum(f.Return_Amount) as Return_Amount, 
       (sum(f.COST)/sum(f.QTY))*sum(f.Return_QTY) as CostPI
FROM fact_retail f INNER JOIN dim_date d
ON f.key_date = d.date_key
WHERE (
f.key_sub_category IN ( '4339') OR
f.key_item_descr IN
(select '4687' union
 select key_item_desc from dim_item_descr
 where item_desc like '%bracelet%' and item_desc like '%rubber%' and key_item_desc is not null
)
)
AND year(d.date_value)= year(${today})
AND d.date_value <= ${today}
GROUP BY f.key_item_descr
)d) as total_rubber_bracelet_profit_ytd

,
(SELECT SUM(mag_units_sold)
  FROM fact_retail_analysis
  WHERE key_date = ${today}) AS total_mag_units
 ,
(SELECT SUM(mag_units_sold)
 FROM fact_retail_analysis
 WHERE key_date = ${sameDayLastYear})  AS total_mag_units_sdly
,
(SELECT SUM(mag_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  AND key_date <= ${today})  AS total_mag_units_wtd
 ,
(SELECT SUM(mag_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND quarter(key_date)=quarter(${today})
  AND key_date <= ${today})  AS total_mag_units_qtd
,
(SELECT SUM(mag_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  AND key_date <= ${today})  AS total_mag_units_mtd
 ,
(SELECT SUM(mag_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND key_date <= ${today})  AS total_mag_units_ytd
,
(SELECT SUM(mag_profit)
  FROM fact_retail_analysis
  WHERE key_date = ${today})  AS total_mag_profit
 ,
(SELECT SUM(mag_profit)
 FROM fact_retail_analysis
 WHERE key_date = ${sameDayLastYear})  AS total_mag_profit_sdly
,
(SELECT SUM(mag_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  AND key_date <= ${today})  AS total_mag_profit_wtd
 ,
(SELECT SUM(mag_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND quarter(key_date)=quarter(${today})
  AND key_date <= ${today})  AS total_mag_profit_qtd
,
(SELECT SUM(mag_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  AND key_date <= ${today})  AS total_mag_profit_mtd
 ,
(SELECT SUM(mag_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND key_date <= ${today})  AS total_mag_profit_ytd

,
(SELECT	SUM(dt.musag_units_sold) 
FROM
(
SELECT DATE_FORMAT(f.key_date,'%Y%m%d') as key_date,
SUM(f.quantity) AS musag_units_sold
FROM fact_museum_audio_new f 
WHERE DATE_FORMAT(f.key_date,'%Y%m%d') = (DATE_FORMAT(${today},'%Y%m%d'))
AND f.key_museum_category  <> '2209'
UNION
SELECT DATE_FORMAT(key_date,'%Y%m%d')  AS key_date,
SUM(musag_units_sold) AS musag_units_sold
FROM fact_retail_analysis f 
WHERE f.key_date = ${today}
)dt) AS total_mus_ag_units
,
(SELECT	SUM(dt.musag_units_sold) 
FROM
(
SELECT DATE_FORMAT(f.key_date,'%Y%m%d') as key_date,
SUM(f.quantity) AS musag_units_sold
FROM fact_museum_audio_new f 
WHERE DATE_FORMAT(f.key_date,'%Y%m%d') = (DATE_FORMAT(${sameDayLastYear},'%Y%m%d'))
AND f.key_museum_category  <> '2209'
UNION
SELECT DATE_FORMAT(key_date,'%Y%m%d')  AS key_date,
SUM(musag_units_sold) AS musag_units_sold
FROM fact_retail_analysis f 
WHERE f.key_date = ${sameDayLastYear}
)dt) AS total_mus_ag_units_sdly
,
(SELECT	SUM(dt.musag_units_sold) 
FROM
(
SELECT DATE_FORMAT(f.key_date,'%Y%m%d') as key_date,
SUM(f.quantity) AS musag_units_sold
FROM fact_museum_audio_new f 
WHERE year(DATE_FORMAT(f.key_date,'%Y%m%d'))=year((DATE_FORMAT(${today},'%Y%m%d')))
AND weekofyear(DATE_FORMAT(f.key_date,'%Y%m%d'))=weekofyear((DATE_FORMAT(${today},'%Y%m%d')))
AND DATE_FORMAT(f.key_date,'%Y%m%d') <= (DATE_FORMAT(${today},'%Y%m%d'))
AND f.key_museum_category  <> '2209'
GROUP BY f.key_date
UNION
SELECT DATE_FORMAT(key_date,'%Y%m%d')  AS key_date,
SUM(musag_units_sold) AS musag_units_sold
FROM fact_retail_analysis f 
WHERE year(f.key_date)= year(${today})
AND weekofyear(f.key_date)=weekofyear(${today})
AND f.key_date <= ${today}
GROUP BY f.key_date
)dt)  AS total_mus_ag_units_wtd
,
(SELECT	SUM(dt.musag_units_sold) 
FROM
(
SELECT DATE_FORMAT(f.key_date,'%Y%m%d') as key_date,
SUM(f.quantity) AS musag_units_sold
FROM fact_museum_audio_new f 
WHERE year(DATE_FORMAT(f.key_date,'%Y%m%d'))=year((DATE_FORMAT(${today},'%Y%m%d')))
AND quarter(DATE_FORMAT(f.key_date,'%Y%m%d'))=quarter((DATE_FORMAT(${today},'%Y%m%d')))
AND DATE_FORMAT(f.key_date,'%Y%m%d') <= (DATE_FORMAT(${today},'%Y%m%d'))
AND f.key_museum_category  <> '2209'
GROUP BY f.key_date
UNION
SELECT DATE_FORMAT(key_date,'%Y%m%d')  AS key_date,
SUM(musag_units_sold) AS musag_units_sold
FROM fact_retail_analysis f 
WHERE year(f.key_date)= year(${today})
AND quarter(f.key_date)=quarter(${today})
AND f.key_date <= ${today}
GROUP BY f.key_date
)dt)  AS total_mus_ag_units_qtd
,
(SELECT	SUM(dt.musag_units_sold) 
FROM
(
SELECT DATE_FORMAT(f.key_date,'%Y%m%d') as key_date,
SUM(f.quantity) AS musag_units_sold
FROM fact_museum_audio_new f 
WHERE year(DATE_FORMAT(f.key_date,'%Y%m%d'))=year((DATE_FORMAT(${today},'%Y%m%d')))
AND month(DATE_FORMAT(f.key_date,'%Y%m%d'))=month((DATE_FORMAT(${today},'%Y%m%d')))
AND DATE_FORMAT(f.key_date,'%Y%m%d') <= (DATE_FORMAT(${today},'%Y%m%d'))
AND f.key_museum_category  <> '2209'
GROUP BY f.key_date
UNION
SELECT DATE_FORMAT(key_date,'%Y%m%d')  AS key_date,
SUM(musag_units_sold) AS musag_units_sold
FROM fact_retail_analysis f 
WHERE year(f.key_date)= year(${today})
AND month(f.key_date)=month(${today})
AND f.key_date <= ${today}
GROUP BY f.key_date
)dt)  AS total_mus_ag_units_mtd
,
(SELECT	SUM(dt.musag_units_sold) 
FROM
(
SELECT DATE_FORMAT(f.key_date,'%Y%m%d') as key_date,
SUM(f.quantity) AS musag_units_sold
FROM fact_museum_audio_new f 
WHERE year(DATE_FORMAT(f.key_date,'%Y%m%d'))=year((DATE_FORMAT(${today},'%Y%m%d')))
AND DATE_FORMAT(f.key_date,'%Y%m%d') <= (DATE_FORMAT(${today},'%Y%m%d'))
AND f.key_museum_category  <> '2209'
GROUP BY f.key_date
UNION
SELECT DATE_FORMAT(key_date,'%Y%m%d')  AS key_date,
SUM(musag_units_sold) AS musag_units_sold
FROM fact_retail_analysis f 
WHERE year(f.key_date)= year(${today})
AND f.key_date <= ${today}
GROUP BY f.key_date
)dt)  AS total_mus_ag_units_ytd
,

(SELECT	SUM(dt.audio_headset_revenue) 
FROM
(
SELECT DATE_FORMAT(f.key_date,'%Y%m%d') as key_date,
SUM(f.amount) AS audio_headset_revenue
FROM fact_museum_audio_new f 
WHERE DATE_FORMAT(f.key_date,'%Y%m%d') = (DATE_FORMAT(${today},'%Y%m%d'))
GROUP BY f.key_date
UNION
SELECT DATE_FORMAT(key_date,'%Y%m%d')  AS key_date,
SUM(musag_profit) AS audio_headset_revenue
FROM fact_retail_analysis f 
WHERE f.key_date = ${today}
GROUP BY f.key_date
)dt)  AS total_mus_ag_profit
,

(SELECT	SUM(dt.audio_headset_revenue) 
FROM
(
SELECT DATE_FORMAT(f.key_date,'%Y%m%d') as key_date,
SUM(f.amount) AS audio_headset_revenue
FROM fact_museum_audio_new f 
WHERE DATE_FORMAT(f.key_date,'%Y%m%d') = (DATE_FORMAT(${sameDayLastYear},'%Y%m%d'))
GROUP BY f.key_date
UNION
SELECT DATE_FORMAT(key_date,'%Y%m%d')  AS key_date,
SUM(musag_profit) AS audio_headset_revenue
FROM fact_retail_analysis f 
WHERE f.key_date = ${sameDayLastYear}
GROUP BY f.key_date
)dt)  AS total_mus_ag_profit_sdly

,
(SELECT
	SUM(dt.audio_headset_revenue) 
FROM
(
SELECT DATE_FORMAT(f.key_date,'%Y%m%d') as key_date,
SUM(f.amount) AS audio_headset_revenue
FROM fact_museum_audio_new f 
WHERE year(DATE_FORMAT(f.key_date,'%Y%m%d'))=year((DATE_FORMAT(${today},'%Y%m%d')))
AND weekofyear(DATE_FORMAT(f.key_date,'%Y%m%d'))=weekofyear((DATE_FORMAT(${today},'%Y%m%d')))
AND DATE_FORMAT(f.key_date,'%Y%m%d') <= (DATE_FORMAT(${today},'%Y%m%d'))
GROUP BY f.key_date
UNION
SELECT DATE_FORMAT(key_date,'%Y%m%d')  AS key_date,
SUM(musag_profit) AS audio_headset_revenue
FROM fact_retail_analysis f 
WHERE year(f.key_date)= year(${today})
AND weekofyear(f.key_date)=weekofyear(${today})
AND f.key_date <= ${today}
GROUP BY f.key_date
)dt)  AS total_mus_ag_profit_wtd
,
(SELECT
	SUM(dt.audio_headset_revenue) 
FROM
(
SELECT DATE_FORMAT(f.key_date,'%Y%m%d') as key_date,
SUM(f.amount) AS audio_headset_revenue
FROM fact_museum_audio_new f 
WHERE year(DATE_FORMAT(f.key_date,'%Y%m%d'))=year((DATE_FORMAT(${today},'%Y%m%d')))
AND quarter(DATE_FORMAT(f.key_date,'%Y%m%d'))=quarter((DATE_FORMAT(${today},'%Y%m%d')))
AND DATE_FORMAT(f.key_date,'%Y%m%d') <= (DATE_FORMAT(${today},'%Y%m%d'))
GROUP BY f.key_date
UNION
SELECT DATE_FORMAT(key_date,'%Y%m%d')  AS key_date,
SUM(musag_profit) AS audio_headset_revenue
FROM fact_retail_analysis f 
WHERE year(f.key_date)= year(${today})
AND quarter(f.key_date)=quarter(${today})
AND f.key_date <= ${today}
GROUP BY f.key_date
)dt)  AS total_mus_ag_profit_qtd
,

(SELECT	SUM(dt.audio_headset_revenue) 
FROM
(
SELECT DATE_FORMAT(f.key_date,'%Y%m%d') as key_date,
SUM(f.amount) AS audio_headset_revenue
FROM fact_museum_audio_new f 
WHERE year(DATE_FORMAT(f.key_date,'%Y%m%d'))=year((DATE_FORMAT(${today},'%Y%m%d')))
AND month(DATE_FORMAT(f.key_date,'%Y%m%d'))=month((DATE_FORMAT(${today},'%Y%m%d')))
AND DATE_FORMAT(f.key_date,'%Y%m%d') <= (DATE_FORMAT(${today},'%Y%m%d'))
GROUP BY f.key_date
UNION
SELECT DATE_FORMAT(key_date,'%Y%m%d')  AS key_date,
SUM(musag_profit) AS audio_headset_revenue
FROM fact_retail_analysis f 
WHERE year(f.key_date)= year(${today})
AND month(f.key_date)=month(${today})
AND f.key_date <= ${today}
GROUP BY f.key_date
)dt)  AS total_mus_ag_profit_mtd

,
(SELECT	SUM(dt.audio_headset_revenue) 
FROM
(
SELECT DATE_FORMAT(f.key_date,'%Y%m%d') as key_date,
SUM(f.amount) AS audio_headset_revenue
FROM fact_museum_audio_new f 
WHERE year(DATE_FORMAT(f.key_date,'%Y%m%d'))=year((DATE_FORMAT(${today},'%Y%m%d')))
AND DATE_FORMAT(f.key_date,'%Y%m%d') <= (DATE_FORMAT(${today},'%Y%m%d'))
GROUP BY f.key_date
UNION
SELECT DATE_FORMAT(key_date,'%Y%m%d')  AS key_date,
SUM(musag_profit) AS audio_headset_revenue
FROM fact_retail_analysis f 
WHERE year(f.key_date)= year(${today})
AND f.key_date <= ${today}
GROUP BY f.key_date
)dt)  AS total_mus_ag_profit_ytd

,
(SELECT SUM(cafe_medallion_units_sold)
  FROM fact_retail_analysis
  WHERE key_date = ${today}) AS total_cafe_mm_units
 ,
(SELECT SUM(cafe_medallion_units_sold)
 FROM fact_retail_analysis
 WHERE key_date = ${sameDayLastYear})  AS total_cafe_mm_units_sdly
,
(SELECT SUM(cafe_medallion_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  AND key_date <= ${today})  AS total_cafe_mm_units_wtd
,
(SELECT SUM(cafe_medallion_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND quarter(key_date)=quarter(${today})
  AND key_date <= ${today})  AS total_cafe_mm_units_qtd
,
(SELECT SUM(cafe_medallion_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  AND key_date <= ${today})  AS total_cafe_mm_units_mtd
 ,
(SELECT SUM(cafe_medallion_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND key_date <= ${today})  AS total_cafe_mm_units_ytd
,
(SELECT SUM(cafe_medallion_profit)
  FROM fact_retail_analysis
  WHERE key_date = ${today})  AS total_cafe_mm_profit
 ,
(SELECT SUM(cafe_medallion_profit)
 FROM fact_retail_analysis
 WHERE key_date = ${sameDayLastYear})  AS total_cafe_mm_profit_sdly
,
(SELECT SUM(cafe_medallion_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  AND key_date <= ${today})  AS total_cafe_mm_profit_wtd
 ,
(SELECT SUM(cafe_medallion_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND quarter(key_date)=quarter(${today})
  AND key_date <= ${today})  AS total_cafe_mm_profit_qtd
,
(SELECT SUM(cafe_medallion_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  AND key_date <= ${today})  AS total_cafe_mm_profit_mtd
 ,
(SELECT SUM(cafe_medallion_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND key_date <= ${today})  AS total_cafe_mm_profit_ytd
,
(SELECT SUM(cafe_medallion_sales)
  FROM fact_retail_analysis
  WHERE key_date = ${today})  AS total_cafe_mm_sales
 ,
(SELECT SUM(cafe_medallion_sales)
 FROM fact_retail_analysis
 WHERE key_date = ${sameDayLastYear})  AS total_cafe_mm_sales_sdly
,
(SELECT SUM(cafe_medallion_sales)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  AND key_date <= ${today})  AS total_cafe_mm_sales_wtd
 ,
(SELECT SUM(cafe_medallion_sales)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND quarter(key_date)=quarter(${today})
  AND key_date <= ${today})  AS total_cafe_mm_sales_qtd
,
(SELECT SUM(cafe_medallion_sales)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  AND key_date <= ${today})  AS total_cafe_mm_sales_mtd
,
(SELECT SUM(cafe_medallion_sales)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND key_date <= ${today})  AS total_cafe_mm_sales_ytd

,
(SELECT audio_tour_headsets
FROM fact_dpr_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
AND d.date_value=${today}) AS audio_tour_headset_budget
,
(SELECT SUM(audio_tour_headsets)
FROM fact_dpr_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
AND d.date_value=${sameDayLastYear}) AS audio_tour_headset_budget_sdly
,
(SELECT SUM(audio_tour_headsets)
FROM fact_dpr_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
and year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) AS audio_tour_headset_budget_wtd
,
(SELECT SUM(audio_tour_headsets)
FROM fact_dpr_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
and year(d.date_value)= year(${today})
AND month(d.date_value) = month(${today})
and d.date_value <= ${today}) AS audio_tour_headset_budget_mtd
,
(SELECT SUM(audio_tour_headsets)
FROM fact_dpr_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
and year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) AS audio_tour_headset_budget_qtd
,
(SELECT SUM(audio_tour_headsets)
FROM fact_dpr_forecasts r inner join 911dw.dim_date d
on r.key_date = d.date_key
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) AS audio_tour_headset_budget_ytd
,

(SELECT SUM(mus_tour_guides_units_sold)
  FROM fact_retail_analysis
  WHERE key_date = ${today}) AS total_mus_tour_guides_units
,
(SELECT SUM(mus_tour_guides_units_sold)
 FROM fact_retail_analysis
 WHERE key_date = ${sameDayLastYear})  AS total_mus_tour_guides_units_sdly
,
(SELECT SUM(mus_tour_guides_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  AND key_date <= ${today})  AS total_mus_tour_guides_units_wtd
,
(SELECT SUM(mus_tour_guides_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND quarter(key_date)=quarter(${today})
  AND key_date <= ${today})  AS total_mus_tour_guides_units_qtd
,
(SELECT SUM(mus_tour_guides_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  AND key_date <= ${today})  AS total_mus_tour_guides_units_mtd
,
(SELECT SUM(mus_tour_guides_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND key_date <= ${today})  AS total_mus_tour_guides_units_ytd
,
(SELECT SUM(mus_tour_guides_profit)
  FROM fact_retail_analysis
  WHERE key_date = ${today})  AS total_mus_tour_guides_profit
 ,
(SELECT SUM(mus_tour_guides_profit)
 FROM fact_retail_analysis
 WHERE key_date = ${sameDayLastYear})  AS total_mus_tour_guides_profit_sdly
,
(SELECT SUM(mus_tour_guides_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  AND key_date <= ${today})  AS total_mus_tour_guides_profit_wtd
 ,
(SELECT SUM(mus_tour_guides_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND quarter(key_date)=quarter(${today})
  AND key_date <= ${today})  AS total_mus_tour_guides_profit_qtd
,
(SELECT SUM(mus_tour_guides_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  AND key_date <= ${today})  AS total_mus_tour_guides_profit_mtd
 ,
(SELECT SUM(mus_tour_guides_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND key_date <= ${today})  AS total_mus_tour_guides_profit_ytd

,
(SELECT SUM(mus_memberships_units_sold)
  FROM fact_retail_analysis
  WHERE key_date = ${today}) AS total_mus_memberships_units
,
(SELECT SUM(mus_memberships_units_sold)
 FROM fact_retail_analysis
 WHERE key_date = ${sameDayLastYear})  AS total_mus_memberships_units_sdly
,
(SELECT SUM(mus_memberships_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  AND key_date <= ${today})  AS total_mus_memberships_units_wtd
,
(SELECT SUM(mus_memberships_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND quarter(key_date)=quarter(${today})
  AND key_date <= ${today})  AS total_mus_memberships_units_qtd
,
(SELECT SUM(mus_memberships_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  AND key_date <= ${today})  AS total_mus_memberships_units_mtd
,
(SELECT SUM(mus_memberships_units_sold)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND key_date <= ${today})  AS total_mus_memberships_units_ytd
,
(SELECT SUM(mus_memberships_profit)
  FROM fact_retail_analysis
  WHERE key_date = ${today})  AS total_mus_memberships_profit
 ,
(SELECT SUM(mus_memberships_profit)
 FROM fact_retail_analysis
 WHERE key_date = ${sameDayLastYear})  AS total_mus_memberships_profit_sdly
,
(SELECT SUM(mus_memberships_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND weekofyear(key_date)=weekofyear(${today})
  AND key_date <= ${today})  AS total_mus_memberships_profit_wtd
 ,
(SELECT SUM(mus_memberships_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND quarter(key_date)=quarter(${today})
  AND key_date <= ${today})  AS total_mus_memberships_profit_qtd
,
(SELECT SUM(mus_memberships_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  AND key_date <= ${today})  AS total_mus_memberships_profit_mtd
 ,
(SELECT SUM(mus_memberships_profit)
 FROM fact_retail_analysis
 WHERE year(key_date)= year(${today})
  AND key_date <= ${today})  AS total_mus_memberships_profit_ytd
,
(select sum(box_office_mus_exit_don) 
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${today}) as box_office_mus_exit_don
,
(select sum(box_office_mus_exit_don) 
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${sameDayLastYear}) as box_office_mus_exit_don_sdly
,
(SELECT sum(box_office_mus_exit_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as box_office_mus_exit_don_wtd
,
(select sum(box_office_mus_exit_don) 
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}) as box_office_mus_exit_don_mtd
,
(SELECT sum(box_office_mus_exit_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as box_office_mus_exit_don_qtd
,
(select sum(box_office_mus_exit_don) 
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value) = year(${today})
and d.date_value<= ${today}) as box_office_mus_exit_don_ytd
,
(select sum(box_office_mem_don)
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${today}) as box_office_mem_don
,
(select sum(box_office_mem_don) 
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${sameDayLastYear}) as box_office_mem_don_sdly
,
(SELECT sum(box_office_mem_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND weekofyear(d.date_value) = weekofyear(${today})
and d.date_value <= ${today}) as box_office_mem_don_wtd
,
(select sum(box_office_mem_don)
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}) as box_office_mem_don_mtd
,
(SELECT sum(box_office_mem_don)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where year(d.date_value)= year(${today})
AND quarter(d.date_value) = quarter(${today})
and d.date_value <= ${today}) as box_office_mem_don_qtd
,
(select sum(box_office_mem_don)
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value) = year(${today})
and d.date_value<= ${today}) as box_office_mem_don_ytd

-- ===== [datasources/sql-ds.xml] query: SameDayLastYear =====
select k, dayinyear, d.date_value
from
(select p.day_in_year as 'k' from dim_date p inner join dim_date t where
year(p.date_value)=year(${today})-1
and  p.day_in_week=t.day_in_week
and t.date_value=MAKEDATE( EXTRACT(YEAR FROM ${today}),1)
order by k limit 1)table1,
(select p.day_in_year as 'dayinyear' from dim_date p
where p.date_value=${today})table2, 
dim_date d
where 
d.date_value = ADDDATE(MAKEDATE( EXTRACT(YEAR FROM ${today})-1,1), INTERVAL k+dayinyear-2 DAY)