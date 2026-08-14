-- REPORT: M&M Daily Tracker - YTD (memorial_museum_daily_tracker_ytd)

-- ===== [datasources/sql-ds.xml] query: Master =====
SELECT 
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
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as mem_attendance_wtd
,
(select sum(mem_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as mem_attendance_mtd
,
(select sum(mem_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as mem_attendance_ytd
, 
(select sum(mem_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value <= ${today} ) as mem_attendance_lifetime
,
(select mem_attendance 
from fact_forecasted_value_for_date f inner join  dim_date d on f.key_date= d.date_key
where 
 f.key_facility =1003
and d.date_value = ${today}) as mem_attendance_budget
,
(select sum(mem_attendance) 
from fact_forecasted_value_for_date f inner join  dim_date d on f.key_date= d.date_key
where 
 f.key_facility =1003
and d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as mem_attendance_budget_wtd
,
(select sum(mem_attendance) 
from fact_forecasted_value_for_date f inner join  dim_date d on f.key_date= d.date_key
where f.key_facility =1003 and
case when year(${today}) = 2020 and month(${today})= 7 
then d.date_value >= '20200704' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end) as mem_attendance_budget_mtd
,
(select sum(mem_attendance) 
from fact_forecasted_value_for_date f inner join  dim_date d on f.key_date= d.date_key
where f.key_facility =1003
and year(d.date_value) = year(${today})
and d.date_value <= ${today}) as mem_attendance_budget_ytd
, 
(select sum(mus_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value <= ${today} ) as mus_attendance_lifetime
,
(select sum(virtual_mem_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as virtual_mem_tours_wtd
,
(select sum(virtual_mem_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as virtual_mem_tours
,
(select sum(virtual_mem_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as virtual_mem_tours_mtd
,
(select sum(virtual_mem_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as virtual_mem_tours_ytd
,
(select sum(virtual_mem_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as virtual_mem_tour_revenue
,
(select sum(virtual_mem_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as virtual_mem_tour_revenue_wtd
,
(select sum(virtual_mem_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as virtual_mem_tour_revenue_mtd
,
(select sum(virtual_mem_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as virtual_mem_tour_revenue_ytd
,
(select sum(virtual_yf_mem_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as virtual_yf_mem_tours
,
(select sum(virtual_yf_mem_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as virtual_yf_mem_tours_wtd

,
(select sum(virtual_yf_mem_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as virtual_yf_mem_tours_mtd
,
(select sum(virtual_yf_mem_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as virtual_yf_mem_tours_ytd
,
(select sum(virtual_yf_mem_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as virtual_yf_mem_tour_revenue
,
(select sum(virtual_yf_mem_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as virtual_yf_mem_tour_revenue_wtd
,
(select sum(virtual_yf_mem_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as virtual_yf_mem_tour_revenue_mtd
,
(select sum(virtual_yf_mem_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as virtual_yf_mem_tour_revenue_ytd
,
(select sum(retail_carts_gross_profit)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as retail_carts_gross_profit
,
(select sum(retail_carts_gross_profit)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as retail_carts_gross_profit_wtd
,
(select sum(retail_carts_gross_profit)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as retail_carts_gross_profit_mtd
,
(select sum(retail_carts_gross_profit)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as retail_carts_gross_profit_ytd
, 

(select profit_from_retail
from fact_retail_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where f.key_facility=1020
and d.date_value = ${today}) as retail_carts_gross_profit_budget
, 

(select sum(profit_from_retail)
from fact_retail_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where f.key_facility=1020
and d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as retail_carts_gross_profit_budget_wtd
,
(select sum(profit_from_retail)
from fact_retail_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where f.key_facility=1020
and case when year(${today}) = 2020 and month(${today})= 7 
then d.date_value >= '20200704' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end) as retail_carts_gross_profit_budget_mtd
,
(select sum(profit_from_retail)
from fact_retail_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where f.key_facility=1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}) as retail_carts_gross_profit_budget_ytd
,
(select sum(ecom_gross_profit)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as ecom_gross_profit 	
,
(select sum(ecom_gross_profit)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as ecom_gross_profit_wtd
,
(select sum(ecom_gross_profit)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where 
case when year(${today}) = 2020 and month(${today})= 7 
then d.date_value >= '20200704' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end ) as ecom_gross_profit_mtd
,
(select sum(ecom_gross_profit)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as ecom_gross_profit_ytd
,
(select profit_from_ecom
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value = ${today}) as ecom_gross_profit_budget
,
(select sum(profit_from_ecom)
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as ecom_gross_profit_budget_wtd
,
(select sum(profit_from_ecom)
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where case when year(${today}) = 2020 and month(${today})= 7 
then d.date_value >= '20200704' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end) as ecom_gross_profit_budget_mtd
,
(select sum(profit_from_ecom)
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today}) as ecom_gross_profit_budget_ytd
,
(select ifnull(sum(mus_attendance),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as mus_attendance
,
(select ifnull(sum(mus_attendance),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as mus_attendance_wtd
,
(select ifnull(sum(mus_attendance),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end ) as mus_attendance_mtd
, 
(select ifnull(sum(mus_attendance),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as mus_attendance_ytd
,
(select new_attendance 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where 
 f.key_facility =1003
and d.date_value = ${today}) as mus_attendance_budget
,
(select sum(new_attendance) 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where 
 f.key_facility =1003
and d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as mus_attendance_budget_wtd
,
(select sum(new_attendance) 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where  f.key_facility =1003
and case when year(${today}) = 2020 and month(${today})= 9
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end) as mus_attendance_budget_mtd
,
(select sum(new_attendance)
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where  f.key_facility =1003
and year(d.date_value) = year(${today})
and d.date_value <= ${today}) as mus_attendance_budget_ytd
,
(select ifnull(sum(tickets_sold),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as tickets_sold
,
(select ifnull(sum(tickets_sold),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as tickets_sold_wtd
,
(select ifnull(sum(tickets_sold),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end ) as tickets_sold_mtd
, 
(select ifnull(sum(tickets_sold),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today}  ) as tickets_sold_ytd
,
(select tickets_sold_for_date 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  d.date_value = ${today}) as tickets_sold_budget
,
(select sum(tickets_sold_for_date) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as tickets_sold_budget_wtd
,
(select sum(tickets_sold_for_date) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end) as tickets_sold_budget_mtd
,
(select sum(tickets_sold_for_date) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today}) as tickets_sold_budget_ytd
,
(select ifnull(sum(ticket_revenue),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as ticket_revenue
,
(select ifnull(sum(ticket_revenue),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as ticket_revenue_wtd
,
(select ifnull(sum(ticket_revenue),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end ) as ticket_revenue_mtd
, 
(select ifnull(sum(ticket_revenue),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today}  ) as ticket_revenue_ytd
,
(select ticket_revenue 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  d.date_value = ${today}) as ticket_revenue_budget
,
(select sum(ticket_revenue) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as ticket_revenue_budget_wtd
,
(select sum(ticket_revenue) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end) as ticket_revenue_budget_mtd
,
(select sum(ticket_revenue) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today}) as ticket_revenue_budget_ytd
,
(select ifnull(sum(pass_revenue),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as pass_revenue
,
(select ifnull(sum(pass_revenue),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as pass_revenue_wtd
,
(select ifnull(sum(pass_revenue),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end ) as pass_revenue_mtd
, 
(select ifnull(sum(pass_revenue),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today}  ) as pass_revenue_ytd
,
(select ifnull(pass_revenue,0) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  d.date_value = ${today}) as pass_revenue_budget
,
(select ifnull(sum(pass_revenue),0) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as pass_revenue_budget_wtd
,
(select ifnull(sum(pass_revenue),0)
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end) as pass_revenue_budget_mtd
,
(select ifnull(sum(pass_revenue), 0)
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today}) as pass_revenue_budget_ytd
,
(select sum(service_fees)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as service_fees
,
(select sum(service_fees)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as service_fees_wtd
,
(select sum(service_fees)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end ) as service_fees_mtd
, 
(select sum(service_fees)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today}  ) as service_fees_ytd
,
(select service_fees 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  d.date_value = ${today}) as service_fees_budget
,
(select sum(service_fees) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as service_fees_budget_wtd
,
(select sum(service_fees) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  case when year(${today}) = 2020 and month(${today})= 9
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end) as service_fees_budget_mtd
,
(select sum(service_fees) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today}) as service_fees_budget_ytd
,
(select ifnull(sum(mus_store_gross_profit),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as mus_store_gross_profit
,
(select ifnull(sum(mus_store_gross_profit),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as mus_store_gross_profit_wtd
,
(select ifnull(sum(mus_store_gross_profit),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end ) as mus_store_gross_profit_mtd
, 
(select ifnull(sum(mus_store_gross_profit),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today}  ) as mus_store_gross_profit_ytd
,
(select profit_from_retail
from fact_retail_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where f.key_facility=1003
and d.date_value = ${today}) as mus_store_gross_profit_budget
,
(select sum(profit_from_retail)
from fact_retail_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where f.key_facility=1003
and d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as mus_store_gross_profit_budget_wtd
,
(select sum(profit_from_retail)
from fact_retail_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where f.key_facility=1003
and case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end) as mus_store_gross_profit_budget_mtd
,
(select sum(profit_from_retail)
from fact_retail_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where f.key_facility=1003
and year(d.date_value) = year(${today})
and d.date_value <= ${today}) as mus_store_gross_profit_budget_ytd
,
(select donations_ticketing
from fact_dpr_forecasts f inner join  dim_date d on f.key_date= d.date_key
where  d.date_value = ${today}) as ticketing_donations_budget
,
(select sum(donations_ticketing)
from fact_dpr_forecasts f inner join  dim_date d on f.key_date= d.date_key
where  d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as ticketing_donations_budget_wtd
,
(select sum(donations_ticketing)
from fact_dpr_forecasts f inner join  dim_date d on f.key_date= d.date_key
where  case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end) as ticketing_donations_budget_mtd
,
(select sum(donations_ticketing)
from fact_dpr_forecasts f inner join  dim_date d on f.key_date= d.date_key
where  year(d.date_value) = year(${today})
and d.date_value <= ${today}) as ticketing_donations_budget_ytd
,
(select museum_exit_donations
from fact_dpr_forecasts f inner join dim_date d on f.key_date= d.date_key
where d.date_value = ${today}) as mus_exit_donations_budget
,
(select sum(museum_exit_donations)
from fact_dpr_forecasts f inner join dim_date d on f.key_date= d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as mus_exit_donations_budget_wtd
,
(select sum(museum_exit_donations)
from fact_dpr_forecasts f inner join  dim_date d on f.key_date= d.date_key
where  case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end) as mus_exit_donations_budget_mtd
,
(select sum(museum_exit_donations)
from fact_dpr_forecasts f inner join  dim_date d on f.key_date= d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today}) as mus_exit_donations_budget_ytd
,
(select donations
from fact_retail_forecasts f inner join dim_date d on f.key_date= d.date_key
where d.date_value = ${today}
and f.key_facility=1003) as mus_store_donations_budget
,
(select sum(donations)
from fact_retail_forecasts f inner join dim_date d on f.key_date= d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}
and f.key_facility=1003) as mus_store_donations_budget_wtd
,
(select sum(donations)
from fact_retail_forecasts f inner join  dim_date d on f.key_date= d.date_key
where  case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end
and f.key_facility=1003) as mus_store_donations_budget_mtd
,
(select sum(donations)
from fact_retail_forecasts f inner join  dim_date d on f.key_date= d.date_key
where  year(d.date_value) = year(${today})
and d.date_value <= ${today}
and f.key_facility=1003) as mus_store_donations_budget_ytd
,
(select donations
from fact_retail_forecasts f inner join dim_date d on f.key_date= d.date_key
where d.date_value = ${today}
and f.key_facility=1020) as mem_cart_donations_budget
,
(select sum(donations)
from fact_retail_forecasts f inner join dim_date d on f.key_date= d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}
and f.key_facility=1020) as mem_cart_donations_budget_wtd
,
(select sum(donations)
from fact_retail_forecasts f inner join  dim_date d on f.key_date= d.date_key
where  d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today}
and f.key_facility=1020) as mem_cart_donations_budget_mtd
,
(select sum(donations)
from fact_retail_forecasts f inner join  dim_date d on f.key_date= d.date_key
where  year(d.date_value) = year(${today})
and d.date_value <= ${today}
and f.key_facility=1020) as mem_cart_donations_budget_ytd
,
(select sum(cart_donation_ask)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as cart_donation_ask
,
(select sum(cart_donation_ask)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as cart_donation_ask_wtd
,
(select sum(cart_donation_ask)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as cart_donation_ask_mtd
,
(select sum(cart_donation_ask)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as cart_donation_ask_ytd
,
(select sum(mus_donation_box)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as donation_box
,
(select sum(mus_donation_box)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as donation_box_wtd
,
(select sum(mus_donation_box)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as donation_box_mtd
,
(select sum(mus_donation_box)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as donation_box_ytd
,
(select sum(r.Amount)
from fact_retail r inner join  dim_date d on r.key_date = d.date_key
where r.key_facility = 1234
and r.key_summary_category = 6
and d.date_value = ${today}) as ecom_donation_ask
,
(select sum(r.Amount)
from fact_retail r inner join  dim_date d on r.key_date = d.date_key
where r.key_facility = 1234
and r.key_summary_category = 6
and d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as ecom_donation_ask_wtd
,
(select sum(r.Amount)
from fact_retail r inner join  dim_date d on r.key_date = d.date_key
where r.key_facility = 1234
and r.key_summary_category = 6
and case when year(${today}) = 2020 and month(${today})= 7 
then d.date_value >= '20200704' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end ) as ecom_donation_ask_mtd
,
(select sum(r.Amount)
from fact_retail r inner join  dim_date d on r.key_date = d.date_key
where r.key_facility = 1234
and r.key_summary_category = 6
and year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as ecom_donation_ask_ytd
,
(select sum(f.amount) as ticketing_donations
from fact_museum_ticketing_donations_issued f  inner join dim_date d
on f.key_date=d.date_key
where f.key_museum_category not in (1131,1359,1909)
and d.date_value = ${today}) as ticketing_donations
,
(select sum(f.amount) as ticketing_donations
from fact_museum_ticketing_donations_issued f inner join dim_date d
on f.key_date=d.date_key
where f.key_museum_category not in (1131,1359,1909)
and d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as ticketing_donations_wtd
,
(select sum(f.amount) as ticketing_donations
from fact_museum_ticketing_donations_issued f inner join dim_date d
on f.key_date=d.date_key
where f.key_museum_category not in (1131,1359,1909)
and case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end ) as ticketing_donations_mtd
,
(
select sum(issued)+sum(unissued) as ticketing_donations
from (
	select f.amount as issued, 0 as unissued
	from fact_museum_ticketing_donations_issued f
	inner join dim_date d on f.key_date = d.date_key
	where f.key_museum_category not in (1131,1359,1909)
	and year(d.date_value) = year(${today})
	and d.date_value<= ${today}
	
	union all
	
	select 0 as issued, fu.amount as unissued
	from fact_museum_ticketing_donations_unissued fu
	inner join dim_date d on fu.key_date = d.date_key
	where fu.key_museum_category not in (1131,1359,1909)
	and year(d.date_value) = year(${today})
	and d.date_value<= ${today}
) as combined
) as ticketing_donations_ytd
,
(select sum(r.Amount+r.Return_Amount) as donations 
from fact_retail r inner join dim_date d on r.key_date=d.date_key
 where r.key_item_descr in ('886')  
and d.date_value = ${today}) as mus_exit_donations
,
(select sum(r.Amount+r.Return_Amount) as donations 
from fact_retail r inner join dim_date d on r.key_date=d.date_key
 where r.key_item_descr in ('886')  
and d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as mus_exit_donations_wtd
,
(select sum(r.Amount+r.Return_Amount) as donations 
from fact_retail r inner join dim_date d on r.key_date=d.date_key
 where r.key_item_descr in ('886')  
and case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end) as mus_exit_donations_mtd
,
(select sum(r.Amount+r.Return_Amount) as donations 
from fact_retail r inner join dim_date d on r.key_date=d.date_key
 where r.key_item_descr in ('886')  
 and year(d.date_value) = year(${today})
and d.date_value <= ${today}) as mus_exit_donations_ytd
,
(SELECT (sum(r.Amount)+sum(r.Return_Amount)) as donations
FROM 911dw.fact_retail r 
inner join  911dw.dim_facility f on f.key_facility = r.key_facility
inner join 911dw.dim_date d on r.key_date = d.date_key
WHERE 
 r.key_item_descr in (483,5156,5179,482,485,2168,2169,2170,2171,2172,2173,3753)
AND f.key_facility = 1003
AND r.key_summary_category = 6
AND d.date_value = ${today}) as mus_store_donations
,
(SELECT (sum(r.Amount)+sum(r.Return_Amount)) as donations
FROM 911dw.fact_retail r 
inner join  911dw.dim_facility f on f.key_facility = r.key_facility
inner join 911dw.dim_date d on r.key_date = d.date_key
WHERE 
 r.key_item_descr in (483,5156,5179,482,485,2168,2169,2170,2171,2172,2173,3753)
AND f.key_facility = 1003
AND r.key_summary_category = 6
AND d.date_value >= date_add(${today},interval -6 day) 
and d.date_value <= ${today}) as mus_store_donations_wtd
,
(SELECT (sum(r.Amount)+sum(r.Return_Amount)) as donations
FROM 911dw.fact_retail r 
inner join  911dw.dim_facility f on f.key_facility = r.key_facility
inner join 911dw.dim_date d on r.key_date = d.date_key
WHERE 
 r.key_item_descr in (483,5156,5179,482,485,2168,2169,2170,2171,2172,2173,3753)
AND f.key_facility = 1003
AND r.key_summary_category = 6
AND case when year(${today}) = 2020 and month(${today})= 9 
then d.date_value >= '20200911' and d.date_value<= ${today}
else year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}
end) as mus_store_donations_mtd
,
(SELECT (sum(r.Amount)+sum(r.Return_Amount)) as donations
FROM 911dw.fact_retail r 
inner join  911dw.dim_facility f on f.key_facility = r.key_facility
inner join 911dw.dim_date d on r.key_date = d.date_key
WHERE 
 r.key_item_descr in (483,5156,5179,482,485,2168,2169,2170,2171,2172,2173,3753)
AND f.key_facility = 1003
AND r.key_summary_category = 6
and year(d.date_value) = year(${today})
AND d.date_value <= ${today}) as mus_store_donations_ytd
,
(select SUM(youth_fam_tour_revenue)
from fact_dpr_report_data f inner join dim_date d on f.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as youth_fam_tour_revenue_ytd
,
(select sum(coatcheck_don)
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value) = year(${today})
and d.date_value<= ${today}) as coatcheck_don_ytd
,
(select sum(virtual_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as virtual_mus_tours
,
(select sum(virtual_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as virtual_mus_tours_mtd
,
(select sum(virtual_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as virtual_mus_tours_ytd
,
(select sum(virtual_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as virtual_mus_tour_revenue
,
(select sum(virtual_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as virtual_mus_tour_revenue_mtd
,
(select sum(virtual_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as virtual_mus_tour_revenue_ytd
,
(select sum(mem_field_trips)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as mem_field_trips
,
(select sum(mem_field_trips)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as mem_field_trips_mtd
,
(select sum(mem_field_trips)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as mem_field_trips_ytd
,
(select sum(mem_field_trip_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as mem_field_trip_revenue
,
(select sum(mem_field_trip_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as mem_field_trip_revenue_mtd
,
(select sum(mem_field_trip_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as mem_field_trip_revenue_ytd
,
(select sum(mus_field_trips)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as mus_field_trips
,
(select sum(mus_field_trips)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as mus_field_trips_mtd
,
(select sum(mus_field_trips)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as mus_field_trips_ytd
,
(select sum(mus_field_trip_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as mus_field_trip_revenue
,
(select sum(mus_field_trip_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as mus_field_trip_revenue_mtd
,
(select sum(mus_field_trip_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as mus_field_trip_revenue_ytd
,
(select sum(mask_donations)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as mask_donations
,
(select sum(mask_donations)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as mask_donations_mtd
,
(select sum(mask_donations)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as mask_donations_ytd
,
(select sum(new_attendance) 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where  f.key_facility =1003
and year(d.date_value) = year(${today})
and d.date_value <= date_add(${date1},interval -15 day)) as mus_col1_budget
,
(select sum(mem_attendance) 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where  f.key_facility =1003
and year(d.date_value) = year(${today})
and d.date_value <= date_add(${date1},interval -15 day)) as mem_col1_budget
,
(select sum(new_attendance) 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where  f.key_facility =1003
and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -14 day)
and d.date_value <= date_add(${date1},interval -8 day)) as mus_col2_budget
,
(select sum(mem_attendance) 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where  f.key_facility =1003
and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -14 day)
and d.date_value <= date_add(${date1},interval -8 day)) as mem_col2_budget
,
(select sum(new_attendance) 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where  f.key_facility =1003
and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -7 day)
and d.date_value <= date_add(${date1},interval -1 day)) as mus_col3_budget
,
(select sum(mem_attendance) 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where  f.key_facility =1003
and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -7 day)
and d.date_value <= date_add(${date1},interval -1 day)) as mem_col3_budget
,
(select sum(new_attendance) 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where  f.key_facility =1003
and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= ${date1}
and d.date_value <= ${today}) as mus_col4_budget
,
(select sum(mem_attendance) 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where  f.key_facility =1003
and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= ${date1}
and d.date_value <= ${today}) as mem_col4_budget
,
(select NULLIF(sum(mus_attendance),0)
from fact_dpr_report_data f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= date_add(${date1},interval -15 day)) as mus_col1
,
(select NULLIF(sum(mem_attendance),0)
from fact_dpr_report_data f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= date_add(${date1},interval -15 day)) as mem_col1
,
(select NULLIF(sum(mus_attendance),0)
from fact_dpr_report_data f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -14 day)
and d.date_value <= date_add(${date1},interval -8 day)) as mus_col2
,
(select NULLIF(sum(mem_attendance),0)
from fact_dpr_report_data f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -14 day)
and d.date_value <= date_add(${date1},interval -8 day)) as mem_col2
,
(select NULLIF(sum(mus_attendance),0)
from fact_dpr_report_data f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -7 day)
and d.date_value <= date_add(${date1},interval -1 day)) as mus_col3
,
(select NULLIF(sum(mem_attendance),0)
from fact_dpr_report_data f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -7 day)
and d.date_value <= date_add(${date1},interval -1 day)) as mem_col3
,
(select NULLIF(sum(mus_attendance),0)
from fact_dpr_report_data f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= ${date1}
and d.date_value <= ${today}) as mus_col4
,
(select NULLIF(sum(mem_attendance),0)
from fact_dpr_report_data f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= ${date1}
and d.date_value <= ${today}) as mem_col4
,

(select (ifnull(sum(virtual_mem_tour_revenue),0) + 
ifnull(sum(virtual_yf_mem_tour_revenue),0) + 
ifnull(sum(retail_carts_gross_profit),0) + 
ifnull(sum(ecom_gross_profit),0)+ 
ifnull(sum(mem_field_trip_revenue),0) +
ifnull(sum(cart_donation_ask),0) +
ifnull(sum(mus_donation_box),0) +
ifnull(sum(mask_donations),0))
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= date_add(${date1},interval -15 day)) as mem_col1_rev1

,
(select sum(r.Amount)
from fact_retail r inner join  dim_date d on r.key_date = d.date_key
where r.key_facility = 1234
and r.key_summary_category = 6
and year(d.date_value) = year(${today})
and d.date_value <= date_add(${date1},interval -15 day)) as mem_col1_rev2
,
(select (ifnull(sum(virtual_mem_tour_revenue),0) + 
ifnull(sum(virtual_yf_mem_tour_revenue),0) + 
ifnull(sum(retail_carts_gross_profit),0) + 
ifnull(sum(ecom_gross_profit),0)+ 
ifnull(sum(mem_field_trip_revenue),0) +
ifnull(sum(cart_donation_ask),0) +
ifnull(sum(mus_donation_box),0) +
ifnull(sum(mask_donations),0))
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -14 day)
and d.date_value <= date_add(${date1},interval -8 day)) as mem_col2_rev1
,
(select sum(r.Amount)
from fact_retail r inner join  dim_date d on r.key_date = d.date_key
where r.key_facility = 1234
and r.key_summary_category = 6
and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -14 day)
and d.date_value <= date_add(${date1},interval -8 day)) as mem_col2_rev2
,
(select (ifnull(sum(virtual_mem_tour_revenue),0) + 
ifnull(sum(virtual_yf_mem_tour_revenue),0) + 
ifnull(sum(retail_carts_gross_profit),0) + 
ifnull(sum(ecom_gross_profit),0)+ 
ifnull(sum(mem_field_trip_revenue),0) +
ifnull(sum(cart_donation_ask),0) +
ifnull(sum(mus_donation_box),0) +
ifnull(sum(mask_donations),0))
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -7 day)
and d.date_value <= date_add(${date1},interval -1 day)) as mem_col3_rev1
,
(select sum(r.Amount)
from fact_retail r inner join  dim_date d on r.key_date = d.date_key
where r.key_facility = 1234
and r.key_summary_category = 6
and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -7 day)
and d.date_value <= date_add(${date1},interval -1 day)) as mem_col3_rev2
,
(select (ifnull(sum(virtual_mem_tour_revenue),0) + 
ifnull(sum(virtual_yf_mem_tour_revenue),0) + 
ifnull(sum(retail_carts_gross_profit),0) + 
ifnull(sum(ecom_gross_profit),0)+ 
ifnull(sum(mem_field_trip_revenue),0) +
ifnull(sum(cart_donation_ask),0) +
ifnull(sum(mus_donation_box),0) +
ifnull(sum(mask_donations),0))
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= ${date1}
and d.date_value <= ${today}) as mem_col4_rev1
,
(select sum(r.Amount)
from fact_retail r inner join  dim_date d on r.key_date = d.date_key
where r.key_facility = 1234
and r.key_summary_category = 6
and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= ${date1}
and d.date_value <= ${today}) as mem_col4_rev2
,
(select (ifnull(sum(ticket_revenue),0) + 
ifnull(sum(service_fees),0) + 
ifnull(sum(pass_revenue),0) + 
ifnull(sum(mus_store_gross_profit),0)+ 
ifnull(sum(virtual_mus_tour_revenue),0) +
ifnull(sum(mus_field_trip_revenue),0)+
ifnull(sum(youth_fam_tour_revenue),0)+
ifnull(sum(mem_mus_tour_revenue),0)+
ifnull(sum(revealed_tour_revenue),0)+
ifnull(sum(ask_educator_revenue),0)+
ifnull(sum(mus_guided_tour_revenue),0)+
ifnull(sum(early_access_tour_revenue),0)+
ifnull(sum(audio_tour_headset),0)+
ifnull(sum(civic_programs),0))
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= date_add(${date1},interval -15 day)) as mus_col1_rev1
,
(select sum(amount) from (
    SELECT (sum(r.Amount)+sum(r.Return_Amount)) as amount
    FROM 911dw.fact_retail r 
    inner join  911dw.dim_facility f on f.key_facility = r.key_facility
    inner join 911dw.dim_date d on r.key_date = d.date_key
    WHERE 
    r.key_item_descr in (483,5156,5179,482,485,2168,2169,2170,2171,2172,2173,3753)
    AND f.key_facility = 1003
    AND r.key_summary_category = 6
    AND year(d.date_value) = year(${today})
    and d.date_value <= date_add(${date1},interval -15 day)

    union all
    select sum(cafe1_donations) as amount
    FROM fact_donations_analysis_report f inner join dim_date d
    on f.key_date = d.date_key
    where year(d.date_value) = year(${today})
    and d.date_value <= date_add(${date1},interval -15 day)
    ) dt) as mus_col1_rev2
,
(
  select sum(amount) as ticketing_donations
  from (
    select f.amount as amount
    from fact_museum_ticketing_donations_issued f inner join dim_date d on f.key_date = d.date_key
    where f.key_museum_category not in (1131,1359,1909)
      and year(d.date_value) = year(${today})
	 and d.date_value <= date_add(${date1},interval -15 day)
    union all
    select fu.amount as amount
    from fact_museum_ticketing_donations_issued f left join fact_museum_ticketing_donations_unissued fu 
      on f.key_date = fu.key_date
      and fu.key_museum_category not in (1131,1359,1909)
    inner join dim_date d on f.key_date = d.date_key
    where f.key_museum_category not in (1131,1359,1909,3220,3221)
      and year(d.date_value) = year(${today})
	 and d.date_value <= date_add(${date1},interval -15 day)
  ) combined
) as mus_col1_rev3
,
(select sum(r.Amount+r.Return_Amount) 
from fact_retail r inner join dim_date d on r.key_date=d.date_key
 where r.key_item_descr in ('886')  
and year(d.date_value) = year(${today})
and d.date_value <= date_add(${date1},interval -15 day)) as mus_col1_rev4
,
(select ifnull(sum(cafe1_profit_all),0)+ifnull(sum(cafe_medallion_profit),0)
from fact_retail_analysis
where year(key_date) = year(${today})
and key_date <= date_add(${date1},interval -15 day)) as mus_col1_rev5
,
(select sum(coatcheck_don)
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= date_add(${date1},interval -15 day)) as mus_col1_rev6
,
(select (ifnull(sum(ticket_revenue),0) + 
ifnull(sum(service_fees),0) + 
ifnull(sum(pass_revenue),0) + 
ifnull(sum(mus_store_gross_profit),0)+ 
ifnull(sum(virtual_mus_tour_revenue),0) +
ifnull(sum(mus_field_trip_revenue),0)+
ifnull(sum(youth_fam_tour_revenue),0)+
ifnull(sum(mem_mus_tour_revenue),0)+
ifnull(sum(revealed_tour_revenue),0)+
ifnull(sum(ask_educator_revenue),0)+
ifnull(sum(mus_guided_tour_revenue),0)+
ifnull(sum(early_access_tour_revenue),0)+
ifnull(sum(audio_tour_headset),0)+
ifnull(sum(civic_programs),0))
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -14 day)
and d.date_value <= date_add(${date1},interval -8 day)) as mus_col2_rev1
,
(select sum(amount) from (
    SELECT (sum(r.Amount)+sum(r.Return_Amount)) as amount
    FROM 911dw.fact_retail r 
    inner join  911dw.dim_facility f on f.key_facility = r.key_facility
    inner join 911dw.dim_date d on r.key_date = d.date_key
    WHERE 
    r.key_item_descr in (483,5156,5179,482,485,2168,2169,2170,2171,2172,2173,3753)
    AND f.key_facility = 1003
    AND r.key_summary_category = 6
    and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
    AND d.date_value >= date_add(${date1},interval -14 day)
    and d.date_value <= date_add(${date1},interval -8 day)

    union all
    select sum(cafe1_donations) as amount
    FROM fact_donations_analysis_report f inner join dim_date d
    on f.key_date = d.date_key
    where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
    AND d.date_value >= date_add(${date1},interval -14 day)
    and d.date_value <= date_add(${date1},interval -8 day)
    ) dt) as mus_col2_rev2
,
(
  select sum(amount) as ticketing_donations
  from (
    select f.amount as amount
    from fact_museum_ticketing_donations_issued f inner join dim_date d on f.key_date = d.date_key
    where f.key_museum_category not in (1131,1359,1909)
    and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
    AND d.date_value >= date_add(${date1},interval -14 day)
    and d.date_value <= date_add(${date1},interval -8 day)
    union all
    select fu.amount as amount
    from fact_museum_ticketing_donations_issued f left join fact_museum_ticketing_donations_unissued fu 
      on f.key_date = fu.key_date
      and fu.key_museum_category not in (1131,1359,1909)
    inner join dim_date d on f.key_date = d.date_key
    where f.key_museum_category not in (1131,1359,1909,3220,3221)
    and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
    AND d.date_value >= date_add(${date1},interval -14 day)
    and d.date_value <= date_add(${date1},interval -8 day)
  ) combined
) as mus_col2_rev3
,
(select sum(r.Amount+r.Return_Amount) 
from fact_retail r inner join dim_date d on r.key_date=d.date_key
where r.key_item_descr in ('886')  
and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -14 day)
and d.date_value <= date_add(${date1},interval -8 day)) as mus_col2_rev4
,
(select ifnull(sum(cafe1_profit_all),0)+ifnull(sum(cafe_medallion_profit),0)
from fact_retail_analysis
where key_date >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and key_date >= date_add(${date1},interval -14 day)
and key_date <= date_add(${date1},interval -8 day)) as mus_col2_rev5
,
(select sum(coatcheck_don)
from fact_donations_analysis_report f inner join dim_date d on f.key_date=d.date_key
where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -14 day)
and d.date_value <= date_add(${date1},interval -8 day)) as mus_col2_rev6
,
(select (ifnull(sum(ticket_revenue),0) + 
ifnull(sum(service_fees),0) + 
ifnull(sum(pass_revenue),0) + 
ifnull(sum(mus_store_gross_profit),0)+ 
ifnull(sum(virtual_mus_tour_revenue),0) +
ifnull(sum(mus_field_trip_revenue),0)+
ifnull(sum(youth_fam_tour_revenue),0)+
ifnull(sum(mem_mus_tour_revenue),0)+
ifnull(sum(revealed_tour_revenue),0)+
ifnull(sum(ask_educator_revenue),0)+
ifnull(sum(mus_guided_tour_revenue),0)+
ifnull(sum(early_access_tour_revenue),0)+
ifnull(sum(audio_tour_headset),0)+
ifnull(sum(civic_programs),0))
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -7 day)
and d.date_value <= date_add(${date1},interval -1 day)) as mus_col3_rev1
,
(select sum(amount) from (
    SELECT (sum(r.Amount)+sum(r.Return_Amount)) as amount
    FROM 911dw.fact_retail r 
    inner join  911dw.dim_facility f on f.key_facility = r.key_facility
    inner join 911dw.dim_date d on r.key_date = d.date_key
    WHERE 
    r.key_item_descr in (483,5156,5179,482,485,2168,2169,2170,2171,2172,2173,3753)
    AND f.key_facility = 1003
    AND r.key_summary_category = 6
    and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
    AND d.date_value >= date_add(${date1},interval -7 day)
    and d.date_value <= date_add(${date1},interval -1 day)

    union all
    select sum(cafe1_donations) as amount
    FROM fact_donations_analysis_report f inner join dim_date d
    on f.key_date = d.date_key
    where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
    AND d.date_value >= date_add(${date1},interval -7 day)
    and d.date_value <= date_add(${date1},interval -1 day)
    ) dt) as mus_col3_rev2
,
(
  select sum(amount) as ticketing_donations
  from (
    select f.amount as amount
    from fact_museum_ticketing_donations_issued f inner join dim_date d on f.key_date = d.date_key
    where f.key_museum_category not in (1131,1359,1909)
    and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
    AND d.date_value >= date_add(${date1},interval -7 day)
    and d.date_value <= date_add(${date1},interval -1 day)
    union all
    select fu.amount as amount
    from fact_museum_ticketing_donations_issued f left join fact_museum_ticketing_donations_unissued fu 
      on f.key_date = fu.key_date
      and fu.key_museum_category not in (1131,1359,1909)
    inner join dim_date d on f.key_date = d.date_key
    where f.key_museum_category not in (1131,1359,1909,3220,3221)
    and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
    AND d.date_value >= date_add(${date1},interval -7 day)
    and d.date_value <= date_add(${date1},interval -1 day)
  ) combined
) as mus_col3_rev3
,
(select sum(r.Amount+r.Return_Amount)
from fact_retail r inner join dim_date d on r.key_date=d.date_key
 where r.key_item_descr in ('886')  
 and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -7 day)
and d.date_value <= date_add(${date1},interval -1 day)) as mus_col3_rev4
,
(select ifnull(sum(cafe1_profit_all),0)+ifnull(sum(cafe_medallion_profit),0)
from fact_retail_analysis
where key_date >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and key_date >= date_add(${date1},interval -7 day)
and key_date <= date_add(${date1},interval -1 day)) as mus_col3_rev5
,
(select sum(coatcheck_don)
from fact_donations_analysis_report f inner join dim_date d on f.key_date=d.date_key
where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= date_add(${date1},interval -7 day)
and d.date_value <= date_add(${date1},interval -1 day)) as mus_col3_rev6
,
(select (ifnull(sum(ticket_revenue),0) + 
ifnull(sum(service_fees),0) + 
ifnull(sum(pass_revenue),0) + 
ifnull(sum(mus_store_gross_profit),0)+ 
ifnull(sum(virtual_mus_tour_revenue),0) +
ifnull(sum(mus_field_trip_revenue),0)+
ifnull(sum(youth_fam_tour_revenue),0)+
ifnull(sum(mem_mus_tour_revenue),0)+
ifnull(sum(revealed_tour_revenue),0)+
ifnull(sum(ask_educator_revenue),0)+
ifnull(sum(mus_guided_tour_revenue),0)+
ifnull(sum(early_access_tour_revenue),0)+
ifnull(sum(audio_tour_headset),0)+
ifnull(sum(civic_programs),0))
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= ${date1}
and d.date_value <= ${today}) as mus_col4_rev1
,
(select sum(amount) from (
    SELECT (sum(r.Amount)+sum(r.Return_Amount)) as amount
    FROM 911dw.fact_retail r 
    inner join  911dw.dim_facility f on f.key_facility = r.key_facility
    inner join 911dw.dim_date d on r.key_date = d.date_key
    WHERE 
    r.key_item_descr in (483,5156,5179,482,485,2168,2169,2170,2171,2172,2173,3753)
    AND f.key_facility = 1003
    AND r.key_summary_category = 6
    and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
    AND d.date_value >= ${date1}
    and d.date_value <= ${today}

    union all
    select sum(cafe1_donations) as amount
    FROM fact_donations_analysis_report f inner join dim_date d
    on f.key_date = d.date_key
    where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
    AND d.date_value >= ${date1}
    and d.date_value <= ${today}
) dt) as mus_col4_rev2
,
(
  select sum(amount) as ticketing_donations
  from (
    select f.amount as amount
    from fact_museum_ticketing_donations_issued f inner join dim_date d on f.key_date = d.date_key
    where f.key_museum_category not in (1131,1359,1909)
    and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
    AND d.date_value >= ${date1}
    and d.date_value <= ${today}
    union all
    select fu.amount as amount
    from fact_museum_ticketing_donations_issued f left join fact_museum_ticketing_donations_unissued fu 
      on f.key_date = fu.key_date
      and fu.key_museum_category not in (1131,1359,1909)
    inner join dim_date d on f.key_date = d.date_key
    where f.key_museum_category not in (1131,1359,1909,3220,3221)
    and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
    AND d.date_value >= ${date1}
    and d.date_value <= ${today}
  ) combined
) as mus_col4_rev3
,
(select sum(r.Amount+r.Return_Amount) 
from fact_retail r inner join dim_date d on r.key_date=d.date_key
 where r.key_item_descr in ('886')  
and d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and d.date_value >= ${date1}
and d.date_value <= ${today}) as mus_col4_rev4
,
(select ifnull(sum(cafe1_profit_all),0)+ifnull(sum(cafe_medallion_profit),0)
from fact_retail_analysis
where key_date >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and key_date >= ${date1}
and key_date <= ${today}) as mus_col4_rev5
,
(select sum(coatcheck_don)
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
and key_date >= ${date1}
and key_date <= ${today}) as mus_col4_rev6
,

(select sum(ea_mem_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as ea_mem_mus_tour_revenue_ytd
,
(select sum(mem_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as mem_mus_tour_revenue_ytd
,
(select sum(revealed_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as revealed_tour_revenue_ytd
,
(select sum(ask_educator_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as ask_educator_revenue_ytd
,
(select sum(civic_programs)
from fact_dpr_report_data f inner join dim_date d on f.key_date=d.date_key
where  year(d.date_value) = year(${today})
and d.date_value <= ${today}) as civic_programs_ytd
,
(select case 
	when year(${date1})=  2020 then weekofyear(${date1})-26
	when year(${date1})= 2021 then weekofyear(${date1})+27
end ) as week4
,
(select case 
    when ${date1} < date_sub(makedate(year(${today}), 1), interval weekday(makedate(year(${today}), 1)) day) 
    then null 
    else date_format(${date1},'%m/%d') 
    end) as date1_col4 
,
(select case 
    when date_add(${date1}, interval 6 day) < date_sub(makedate(year(${today}), 1), interval weekday(makedate(year(${today}), 1)) day) 
    then null 
    else date_format(date_add(${date1}, interval 6 day),'%m/%d') 
    end) as date2_col4 
, 
(select case 
    when date_add(${date1}, interval -7 day) < date_sub(makedate(year(${today}), 1), interval weekday(makedate(year(${today}), 1)) day) 
    then null 
    else date_format(date_add(${date1}, interval -7 day),'%m/%d') 
    end) as date1_col3 
, 
(select case 
    when date_add(${date1}, interval -1 day) < date_sub(makedate(year(${today}), 1), interval weekday(makedate(year(${today}), 1)) day) 
    then null 
    else date_format(date_add(${date1}, interval -1 day),'%m/%d') 
    end) as date2_col3 
, 
(select case 
    when date_add(${date1}, interval -14 day) < date_sub(makedate(year(${today}), 1), interval weekday(makedate(year(${today}), 1)) day) 
    then null 
    else date_format(date_add(${date1}, interval -14 day),'%m/%d') 
    end) as date1_col2 
, 
(select case 
    when date_add(${date1}, interval -8 day) < date_sub(makedate(year(${today}), 1), interval weekday(makedate(year(${today}), 1)) day) 
    then null 
    else date_format(date_add(${date1}, interval -8 day),'%m/%d') 
    end) as date2_col2 
, 
(select case 
    when date_add(${date1}, interval -15 day) < date_sub(makedate(year(${today}), 1), interval weekday(makedate(year(${today}), 1)) day) 
    then null 
    else date_format(date_add(${date1}, interval -15 day),'%m/%d') 
    end) as date2_col1
,
(select (ifnull(sum(ticket_revenue),0) + 
ifnull(sum(service_fees),0) + 
ifnull(sum(pass_revenue),0) )
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= date_add(${date1},interval -15 day)) as adm_rev_col1
,
(select (ifnull(sum(ticket_revenue),0) + 
ifnull(sum(service_fees),0) + 
ifnull(sum(pass_revenue),0) )
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where
year(d.date_value) = year(${today})
and d.date_value >= date_add(${date1},interval -14 day)
and d.date_value <= date_add(${date1},interval -8 day)) as adm_rev_col2
,
(select (ifnull(sum(ticket_revenue),0) + 
ifnull(sum(service_fees),0) + 
ifnull(sum(pass_revenue),0) )
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value >= date_add(${date1},interval -7 day)
and d.date_value <= date_add(${date1},interval -1 day)) as adm_rev_col3
,
(select (ifnull(sum(ticket_revenue),0) + 
ifnull(sum(service_fees),0) + 
ifnull(sum(pass_revenue),0) )
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
and d.date_value >= ${date1}
and d.date_value <= ${today}) as adm_rev_col4
,
(select ifnull(sum(tickets_sold),0) 
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= date_add(${date1},interval -15 day)) as tickets_sold_col1
,
(select ifnull(sum(tickets_sold),0) 
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value >= date_add(${date1},interval -14 day)
and d.date_value <= date_add(${date1},interval -8 day)) as tickets_sold_col2
,
(select ifnull(sum(tickets_sold),0.01) 
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where year(d.date_value) = year(${today})
and d.date_value >= date_add(${date1},interval -7 day)
and d.date_value <= date_add(${date1},interval -1 day)) as tickets_sold_col3
,
(select ifnull(sum(tickets_sold),0) 
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= ${date1}
and d.date_value <= ${today}) as tickets_sold_col4
,
(select sum(mem_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mem_mus_tour_revenue_ytd
, 
(select sum(mus_guided_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mus_guided_tour_revenue_ytd
,
(select sum(early_access_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as early_access_tour_revenue
,
(select sum(early_access_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as early_access_tour_revenue_mtd
, 
(select sum(early_access_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as early_access_tour_revenue_ytd
,
(select sum(audio_tour_headset)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as audio_tour_headset_ytd
,
(select sum(mem_audio_tour_headset)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mem_audio_tour_headset_ytd
,
(select sum(audio_tour_headsets)
from fact_dpr_forecasts f inner join dim_date d on f.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as audio_tour_headset_budget_ytd
,
(SELECT sum(cafe1_donations)
FROM fact_donations_analysis_report f inner join dim_date d
ON f.key_date = d.date_key
WHERE year(d.date_value) = year(${today})
AND d.date_value <= ${today}) as cafe1_donations_ytd
,
(SELECT ifnull(sum(cafe1_profit_all),0)+ifnull(sum(cafe_medallion_profit),0)
FROM fact_retail_analysis
WHERE year(key_date) = year(${today})
AND key_date <= ${today}) as cafe1_profit_ytd
,
(select sum(mem_mus_tour_revenue) 
from fact_forecasted_value_for_date f inner join  dim_date d on f.key_date= d.date_key
where f.key_facility =1003
and year(d.date_value) = year(${today})
and d.date_value <= ${today}) as mem_mus_tour_revenue_budget_ytd
,
(select sum(coatcheck_donations) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today}) as coatcheck_donations_budget_ytd
,
(select sum(mem_audio_guide_revenue) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today}) as mem_audio_guide_revenue_budget_ytd
,
(select sum(early_access_tour_rev) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today}) as early_access_tour_rev_budget_ytd
,
(select sum(guided_tours_revenue) 
from fact_forecasted_value_for_date f inner join  dim_date d on f.key_date= d.date_key
where f.key_facility =1003
and year(d.date_value) = year(${today})
and d.date_value <= ${today}) as guided_tours_revenue_budget_ytd
,
(select sum(cafe_revenue)
from fact_dpr_forecasts f inner join dim_date d on f.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as mus_cafe1_revenue_budget_ytd

-- ===== [datasources/sql-ds.xml] query: Attendance by Day =====
select the_day, 
case when sum(mem_col1)=0 then null
else sum(mem_col1) end as mem_col1, 
case when sum(mus_col1)=0 then null 
else sum(mus_col1) end as mus_col1,  
case when sum(mem_col2)=0 then NULL
else sum(mem_col2) end as mem_col2, 
case when sum(mus_col2)=0 then null
else sum(mus_col2) end as mus_col2, 
case when sum(mem_col3)=0 then NULL
else sum(mem_col3) end as mem_col3, 
case when sum(mus_col3)=0 then null
else sum(mus_col3) end as mus_col3,
case when sum(mem_col4)=0 then NULL
else sum(mem_col4) end as mem_col4, 
case when sum(mus_col4)=0 then null
else sum(mus_col4) end as mus_col4
from
(select key_date, d.day_name as the_day, 
sum(mem_attendance) as mem_col1, 0 as mus_col1,
0 as mem_col2, 0 as mus_col2 , 
0 as mem_col3, 0 as mus_col3,
0 as mem_col4, 0 as mus_col4
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
and year(d.date_value) = year(${today})
and d.date_value <= date_add(${date1},interval -15 day)
group by d.day_name
union 
select key_date, d.day_name as the_day, 
0 as mem_col1, sum(mus_attendance) as mus_col1,
0 as mem_col2, 0 as mus_col2 , 
0 as mem_col3, 0 as mus_col3,
0 as mem_col4, 0 as mus_col4
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
and year(d.date_value) = year(${today})
and d.date_value <= date_add(${date1},interval -15 day)
group by d.day_name
union 
select key_date, d.day_name as the_day, 
0 as mem_col1, 0 as mus_col1, 
sum(mem_attendance) as mem_col2,sum(mus_attendance) as mus_col2 , 
 0 as mem_col3, 0 as mus_col3,
0 as mem_col4, 0 as mus_col4
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
and d.date_value >= date_add(${date1},interval -14 day)
and d.date_value <= date_add(${date1},interval -8 day)
group by d.day_name
UNION
select key_date, d.day_name as the_day, 
0 as mem_col1, 0 as mus_col1, 
0 as  mem_col2, 0 as mus_col2, 
sum(mem_attendance) as mem_col3, sum(mus_attendance) as mus_col3 ,
0 as mem_col4, 0 as mus_col4
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
and d.date_value >= date_add(${date1},interval -7 day)
and d.date_value <= date_add(${date1},interval -1 day)
group by d.day_name
UNION
select key_date, d.day_name as the_day, 
0 as mem_col1, 0 as mus_col1, 
0 as  mem_col2, 0 as mus_col2, 
0 as  mem_col3, 0 as mus_col3,
sum(mem_attendance) as mem_col4, sum(mus_attendance) as mus_col4
from fact_dpr_report_data f inner join dim_date d
on f.key_date = d.date_key
and d.date_value >= ${date1}
and d.date_value <= ${today}
group by d.day_name
) as A
group by the_day
order by key_date

-- ===== [datasources/sql-ds.xml] query: Date1 =====
SELECT 
CASE 
    WHEN weekday(${today})= 0 THEN ${today}
    ELSE (${today} - INTERVAL WEEKDAY(${today}) + 0 DAY) 
END AS date_value

-- ===== [subreport/datasources/sql-ds.xml] query: Attendance by Day =====
select the_day, 
case when sum(mem_col1)=0 then null else sum(mem_col1) end as mem_col1, 
case when sum(mus_col1)=0 then null else sum(mus_col1) end as mus_col1,  
case when sum(mem_col2)=0 then null else sum(mem_col2) end as mem_col2, 
case when sum(mus_col2)=0 then null else sum(mus_col2) end as mus_col2, 
case when sum(mem_col3)=0 then null else sum(mem_col3) end as mem_col3, 
case when sum(mus_col3)=0 then null else sum(mus_col3) end as mus_col3,
case when sum(mem_col4)=0 then null else sum(mem_col4) end as mem_col4, 
case when sum(mus_col4)=0 then null else format(sum(mus_col4),0) end as mus_col4,
case when sum(mus_col4) <=0 then null else sum(mus_col4) end as mus_col4Num
from
(
    select key_date, d.day_name as the_day, 
    sum(mem_attendance) as mem_col1, 0 as mus_col1,
    0 as mem_col2, 0 as mus_col2 , 
    0 as mem_col3, 0 as mus_col3,
    0 as mem_col4, 0 as mus_col4
    from fact_dpr_report_data f 
    inner join dim_date d on f.key_date = d.date_key
    where year(d.date_value) = year(${today})
    and d.date_value <= date_add(${date1},interval -15 day)
    group by d.day_name,d.date_value

    union 
    select key_date, d.day_name as the_day, 
    0 as mem_col1, sum(mus_attendance) as mus_col1,
    0 as mem_col2, 0 as mus_col2 , 
    0 as mem_col3, 0 as mus_col3,
    0 as mem_col4, 0 as mus_col4
    from fact_dpr_report_data f 
    inner join dim_date d on f.key_date = d.date_key
    where year(d.date_value) = year(${today})
    and d.date_value <= date_add(${date1},interval -15 day)
    group by d.day_name,d.date_value
    
    union 
    select key_date, d.day_name as the_day, 
    0 as mem_col1, 0 as mus_col1, 
    sum(mem_attendance) as mem_col2,sum(mus_attendance) as mus_col2 , 
    0 as mem_col3, 0 as mus_col3,
    0 as mem_col4, 0 as mus_col4
    from fact_dpr_report_data f 
    inner join dim_date d on f.key_date = d.date_key
    where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
    and d.date_value >= date_add(${date1},interval -14 day)
    and d.date_value <= date_add(${date1},interval -8 day)
    group by d.day_name,d.date_value
    
    union
    select key_date, d.day_name as the_day, 
    0 as mem_col1, 0 as mus_col1, 
    0 as mem_col2, 0 as mus_col2, 
    sum(mem_attendance) as mem_col3, sum(mus_attendance) as mus_col3 ,
    0 as mem_col4, 0 as mus_col4
    from fact_dpr_report_data f 
    inner join dim_date d on f.key_date = d.date_key
    where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
    and d.date_value >= date_add(${date1},interval -7 day)
    and d.date_value <= date_add(${date1},interval -1 day)
    group by d.day_name,d.date_value
    
    union
    select key_date, d.day_name as the_day, 
    0 as mem_col1, 0 as mus_col1, 
    0 as mem_col2, 0 as mus_col2, 
    0 as mem_col3, 0 as mus_col3,
    sum(mem_attendance) as mem_col4, sum(mus_attendance) as mus_col4
    from fact_dpr_report_data f 
    inner join dim_date d on f.key_date = d.date_key
    where d.date_value >= (
        date_sub(makedate(year(${today}), 1),interval weekday(makedate(year(${today}), 1)) day)
    )
    and d.date_value >= ${date1}
    and d.date_value <= ${today}
    group by d.day_name,d.date_value
) as A
group by the_day
order by FIELD(the_day, 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')