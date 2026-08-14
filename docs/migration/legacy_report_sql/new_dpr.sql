-- REPORT: Daily Performance Report - New (new_dpr)

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
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as mem_attendance_mtd
,
(select sum(mem_attendance)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value>= '20200704'
and d.date_value <= ${today} ) as mem_attendance_jtd
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
(select sum(mem_attendance) 
from fact_forecasted_value_for_date f inner join  dim_date d on f.key_date= d.date_key
where 
 f.key_facility =1003
and d.date_value = ${today}) as mem_attendance_budget
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
where 
 f.key_facility =1003
 and year(d.date_value) = year(${today})
and d.date_value <= ${today}) as mem_attendance_budget_ytd
,
(select sum(mem_attendance) 
from fact_forecasted_value_for_date f inner join  dim_date d on f.key_date= d.date_key
where f.key_facility =1003
and d.date_value >= '20200704'
and d.date_value <= ${today}) as mem_attendance_budget_jtd
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
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as virtual_mem_tours_ytd
,
(select sum(virtual_mem_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200704'
and d.date_value <= ${today} ) as virtual_mem_tours_jtd
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
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as virtual_mem_tour_revenue_mtd
,
(select sum(virtual_mem_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as virtual_mem_tour_revenue_ytd
,
(select sum(virtual_mem_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200704'
and d.date_value <= ${today} ) as virtual_mem_tour_revenue_jtd
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
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as virtual_yf_mem_tours_mtd
,
(select sum(virtual_yf_mem_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as virtual_yf_mem_tours_ytd
,
(select sum(virtual_yf_mem_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200704'
and d.date_value <= ${today} ) as virtual_yf_mem_tours_jtd
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
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as virtual_yf_mem_tour_revenue_mtd
,
(select sum(virtual_yf_mem_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as virtual_yf_mem_tour_revenue_ytd
,
(select sum(virtual_yf_mem_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200704'
and d.date_value <= ${today} ) as virtual_yf_mem_tour_revenue_jtd
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
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as retail_carts_gross_profit_mtd
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
where d.date_value >= '20200704'
and d.date_value <= ${today} ) as retail_carts_gross_profit_jtd
, 

(select profit_from_retail
from fact_retail_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where f.key_facility=1020
and d.date_value = ${today}) as retail_carts_gross_profit_budget
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
(select sum(profit_from_retail)
from fact_retail_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where f.key_facility=1020
and d.date_value >= '20200704'
and d.date_value <= ${today}) as retail_carts_gross_profit_budget_jtd
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
where 
year(d.date_value) = year(${today})
and d.date_value <= ${today}) as ecom_gross_profit_ytd
,
(select sum(ecom_gross_profit)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200704'
and d.date_value <= ${today} ) as ecom_gross_profit_jtd

,
(select profit_from_ecom
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value = ${today}) as ecom_gross_profit_budget
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
(select sum(profit_from_ecom)
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value >= '20200704'
and d.date_value <= ${today}) as ecom_gross_profit_budget_jtd
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
where year(d.date_value) = year(${today})
and d.date_value <= ${today} ) as mus_attendance_ytd
, 
(select ifnull(sum(mus_attendance),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200911'
and d.date_value <= ${today} ) as mus_attendance_jtd
,
(select new_attendance 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where 
 f.key_facility =1003
and d.date_value = ${today}) as mus_attendance_budget
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
and year(d.date_value)= year(${today})
and d.date_value <= ${today}) as mus_attendance_budget_ytd
,
(select sum(new_attendance)
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where  f.key_facility =1003
and d.date_value >= '20200911'
and d.date_value <= ${today}) as mus_attendance_budget_jtd
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
(select ifnull(sum(tickets_sold),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200911'
and d.date_value <= ${today}  ) as tickets_sold_jtd
,
(select tickets_sold_for_date 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  d.date_value = ${today}) as tickets_sold_budget
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
(select sum(tickets_sold_for_date) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value >= '20200911'
and d.date_value <= ${today}) as tickets_sold_budget_jtd
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
(select ifnull(sum(ticket_revenue),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200911'
and d.date_value <= ${today}  ) as ticket_revenue_jtd
,
(select ticket_revenue 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  d.date_value = ${today}) as ticket_revenue_budget
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
(select sum(ticket_revenue) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value >= '20200911'
and d.date_value <= ${today}) as ticket_revenue_budget_jtd
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
(select ifnull(sum(pass_revenue),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200911'
and d.date_value <= ${today}  ) as pass_revenue_jtd
,
(select ifnull(pass_revenue,0) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  d.date_value = ${today}) as pass_revenue_budget
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
(select ifnull(sum(pass_revenue), 0)
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value >= '20200911'
and d.date_value <= ${today}) as pass_revenue_budget_jtd
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
(select sum(service_fees)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200911'
and d.date_value <= ${today}  ) as service_fees_jtd
,
(select service_fees 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  d.date_value = ${today}) as service_fees_budget
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
(select sum(service_fees) 
from fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value >= '20200911'
and d.date_value <= ${today}) as service_fees_budget_jtd

,
(select sum(cafe1_profit_all)+sum(IFNULL(cafe_medallion_profit,0))
from  fact_retail_analysis
where key_date = ${today}) as cafe1_all_profit
,
(select sum(cafe1_profit_all)+sum(IFNULL(cafe_medallion_profit,0))
from  fact_retail_analysis
where year(key_date)= year(${today})
  AND month(key_date)=month(${today})
  and key_date <= ${today}) as cafe1_all_profit_mtd
,
(select sum(cafe1_profit_all)+sum(IFNULL(cafe_medallion_profit,0))
from  fact_retail_analysis
where year(key_date)= year(${today})
    and key_date <= ${today}) as cafe1_all_profit_ytd 
,
(SELECT sum(cafe1_donations)
FROM fact_donations_analysis_report f inner join dim_date d
on f.key_date = d.date_key
where d.date_value = ${today}) as cafe1_donations 
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
and d.date_value <= ${today}) as cafe1_donations_ytd


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
(select ifnull(sum(mus_store_gross_profit),0)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200911'
and d.date_value <= ${today}  ) as mus_store_gross_profit_jtd
,
(select profit_from_retail
from fact_retail_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where f.key_facility=1003
and d.date_value = ${today}) as mus_store_gross_profit_budget
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
(select sum(profit_from_retail)
from fact_retail_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where f.key_facility=1003
and d.date_value >= '20200911'
and d.date_value <= ${today}) as mus_store_gross_profit_budget_jtd

,
(select donations_ticketing
from fact_dpr_forecasts f inner join  dim_date d on f.key_date= d.date_key
where  d.date_value = ${today}) as ticketing_donations_budget
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
(select sum(donations_ticketing)
from fact_dpr_forecasts f inner join  dim_date d on f.key_date= d.date_key
where  d.date_value >= '20200911'
and d.date_value <= ${today}) as ticketing_donations_budget_jtd
,
(select museum_exit_donations
from fact_dpr_forecasts f inner join dim_date d on f.key_date= d.date_key
where d.date_value = ${today}) as mus_exit_donations_budget
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
where  year(d.date_value) = year(${today})
and d.date_value <= ${today}) as mus_exit_donations_budget_ytd
,
(select sum(museum_exit_donations)
from fact_dpr_forecasts f inner join  dim_date d on f.key_date= d.date_key
where  d.date_value >= '20200911'
and d.date_value <= ${today}) as mus_exit_donations_budget_jtd
,
(select donations
from fact_retail_forecasts f inner join dim_date d on f.key_date= d.date_key
where d.date_value = ${today}
and f.key_facility=1003) as mus_store_donations_budget
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
(select sum(donations)
from fact_retail_forecasts f inner join  dim_date d on f.key_date= d.date_key
where  d.date_value >= '20200911'
and d.date_value <= ${today}
and f.key_facility=1003) as mus_store_donations_budget_jtd
,
(select donations
from fact_retail_forecasts f inner join dim_date d on f.key_date= d.date_key
where d.date_value = ${today}
and f.key_facility=1020) as mem_cart_donations_budget
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
(select sum(donations)
from fact_retail_forecasts f inner join  dim_date d on f.key_date= d.date_key
where  d.date_value>= '20200704'
and d.date_value <= ${today}
and f.key_facility=1020) as mem_cart_donations_budget_jtd
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
(select sum(cart_donation_ask)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200704'
and d.date_value <= ${today} ) as cart_donation_ask_jtd
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
(select sum(mus_donation_box)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20200704'
and d.date_value <= ${today} ) as donation_box_jtd
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
(select sum(r.Amount)
from fact_retail r inner join  dim_date d on r.key_date = d.date_key
where r.key_facility = 1234
and r.key_summary_category = 6
and d.date_value >= '20200704'
and d.date_value <= ${today} ) as ecom_donation_ask_jtd
,
(
select sum(issued)+sum(unissued) as ticketing_donations
from(
    select f.amount as issued, 0 as unissued
    from fact_museum_ticketing_donations_issued f
    inner join dim_date d on f.key_date = d.date_key
        where f.key_museum_category not in (1131,1359,1909,3220,3221)
        and d.date_value = ${today}

    union all

    select 0 as issued, fu.amount as unissued
    from fact_museum_ticketing_donations_unissued fu
    inner join dim_date d on fu.key_date = d.date_key
        where fu.key_museum_category not in (1131,1359,1909)
        and d.date_value = ${today}
    ) as combined
) as ticketing_donations

,

(
select sum(issued)+sum(unissued) as ticketing_donations
from (
    select f.amount as issued, 0 as unissued
    from fact_museum_ticketing_donations_issued f
    inner join dim_date d on f.key_date = d.date_key
    where f.key_museum_category not in (1131,1359,1909,3220,3221)
    and 
        case 
            when year(${today}) = 2020 and month(${today})= 9 
            then d.date_value >= ${today} and d.date_value<= ${today}
        else 
            year(d.date_value) = year(${today})
            and month(d.date_value)= month(${today})
            and d.date_value <= ${today}
        end
    union all
    select 0 as issued, fu.amount as unissued
    from fact_museum_ticketing_donations_unissued fu
    inner join dim_date d on fu.key_date = d.date_key
    where fu.key_museum_category not in (1131,1359,1909)
    and 
        case 
            when year(${today}) = 2020 and month(${today})= 9 
            then d.date_value >= ${today} and d.date_value<= ${today}
        else 
            year(d.date_value) = year(${today})
            and month(d.date_value)= month(${today})
            and d.date_value <= ${today}
        end
) as combined
) as ticketing_donations_mtd
,

(
select sum(issued)+sum(unissued) as ticketing_donations
from (
	select f.amount as issued, 0 as unissued
	from fact_museum_ticketing_donations_issued f
	inner join dim_date d on f.key_date = d.date_key
	where f.key_museum_category not in (1131,1359,1909,3220,3221)
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
(
select sum(issued)+sum(unissued) as ticketing_donations
from (
	select f.amount as issued, 0 as unissued
	from fact_museum_ticketing_donations_issued f
	inner join dim_date d on f.key_date = d.date_key
	where f.key_museum_category not in (1131,1359,1909,3220,3221)
	and d.date_value >= '20200911'
    and d.date_value<= ${today}
	
	union all
	
	select 0 as issued, fu.amount as unissued
	from fact_museum_ticketing_donations_unissued fu
	inner join dim_date d on fu.key_date = d.date_key
	where fu.key_museum_category not in (1131,1359,1909)
	and d.date_value >= '20200911'
    and d.date_value<= ${today}
) as combined
) as ticketing_donations_jtd
,
(select sum(r.Amount+r.Return_Amount) as donations 
from fact_retail r inner join dim_date d on r.key_date=d.date_key
 where r.key_item_descr in ('886')  
and d.date_value = ${today}) as mus_exit_donations
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
(select sum(r.Amount+r.Return_Amount) as donations 
from fact_retail r inner join dim_date d on r.key_date=d.date_key
 where r.key_item_descr in ('886')  
 and d.date_value >= '20200911'
and d.date_value <= ${today}) as mus_exit_donations_jtd
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
(SELECT (sum(r.Amount)+sum(r.Return_Amount)) as donations
FROM 911dw.fact_retail r 
inner join  911dw.dim_facility f on f.key_facility = r.key_facility
inner join 911dw.dim_date d on r.key_date = d.date_key
WHERE 
 r.key_item_descr in (483,5156,5179,482,485,2168,2169,2170,2171,2172,2173,3753)
AND f.key_facility = 1003
AND r.key_summary_category = 6
and d.date_value >= '20200911'
AND d.date_value <= ${today}) as mus_store_donations_jtd
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
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as virtual_mus_tours_ytd
,
(select sum(virtual_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20201001'
and d.date_value <= ${today} ) as virtual_mus_tours_jtd
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
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as virtual_mus_tour_revenue_ytd
,
(select sum(virtual_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20201001'
and d.date_value <= ${today} ) as virtual_mus_tour_revenue_jtd
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
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mem_field_trips_ytd
,
(select sum(mem_field_trips)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20201001'
and d.date_value <= ${today} ) as mem_field_trips_jtd
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
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mem_field_trip_revenue_ytd
,
(select sum(mem_field_trip_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20201001'
and d.date_value <= ${today} ) as mem_field_trip_revenue_jtd
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
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mus_field_trips_ytd
,
(select sum(mus_field_trips)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20201001'
and d.date_value <= ${today} ) as mus_field_trips_jtd
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
(select sum(mus_field_trip_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20201001'
and d.date_value <= ${today} ) as mus_field_trip_revenue_jtd
,
(select sum(civic_programs)
from fact_dpr_report_data f inner join dim_date d on f.key_date=d.date_key
where  d.date_value >= '20200704'
and d.date_value <= ${today}) as civic_programs_jtd
,
(select civic_programs 
from fact_dpr_report_data f inner join dim_date d on f.key_date=d.date_key
where  d.date_value = ${today}) as civic_programs
,
(select sum(civic_programs) 
from fact_dpr_report_data f inner join dim_date d on f.key_date=d.date_key
where  d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today}) as civic_programs_mtd
,
(select sum(civic_programs) 
from fact_dpr_report_data f inner join dim_date d on f.key_date=d.date_key
where  d.year4 = year(${today}) 
and d.date_value <= ${today}) as civic_programs_ytd
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
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mask_donations_ytd
,
(select sum(mask_donations)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value >= '20201101'
and d.date_value <= ${today} ) as mask_donations_jtd
,
(select sum(ea_mem_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as ea_mem_mus_tours
,
(select sum(ea_mem_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as ea_mem_mus_tours_mtd
,
(select sum(ea_mem_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as ea_mem_mus_tours_ytd
,
(select sum(ea_mem_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value <= ${today} ) as ea_mem_mus_tours_jtd
,
(select sum(ea_mem_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as ea_mem_mus_tour_revenue
,
(select sum(ea_mem_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as ea_mem_mus_tour_revenue_mtd
,
(select sum(ea_mem_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as ea_mem_mus_tour_revenue_ytd
,
(select sum(ea_mem_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value <= ${today} ) as ea_mem_mus_tour_revenue_jtd
,
(select sum(mem_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as mem_mus_tours
,
(select sum(mem_mus_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as mem_mus_tours_mtd
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
where d.date_value <= ${today} ) as mem_mus_tours_jtd
,
(select sum(mem_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as mem_mus_tour_revenue
,
(select sum(mem_mus_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as mem_mus_tour_revenue_mtd
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
where d.date_value <= ${today} ) as mem_mus_tour_revenue_jtd
,
(select sum(ask_educator_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as ask_educator_revenue
,
(select sum(ask_educator_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as ask_educator_revenue_mtd
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
where d.date_value <= ${today} ) as ask_educator_revenue_jtd
,
(select sum(revealed_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as revealed_tour_revenue
,
(select sum(revealed_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as revealed_tour_revenue_mtd
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
where d.date_value <= ${today} ) as revealed_tour_revenue_jtd
,
(select sum(mus_guided_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as mus_guided_tours
,
(select sum(mus_guided_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as mus_guided_tours_mtd
, 
(select sum(mus_guided_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mus_guided_tours_ytd
,
(select sum(f.guided_tours) from
fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value = ${today}) as mus_guided_tours_budget
,
(select sum(f.guided_tours) from
fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where d.month_number=month(${today})
and  d.year4=year(${today}) 
and d.date_value <= ${today}) as mus_guided_tours_budget_mtd
,
(select sum(f.guided_tours) from
fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where  d.year4=year(${today}) 
and d.date_value <= ${today}) as mus_guided_tours_budget_ytd
,
(select sum(mus_guided_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as mus_guided_tour_revenue
,
(select sum(mus_guided_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as mus_guided_tour_revenue_mtd
, 
(select sum(mus_guided_tour_revenue)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as mus_guided_tour_revenue_ytd
,
(select sum(f.guided_tours_revenue) from
fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value = ${today}) as mus_guided_tour_revenue_budget
,
(select sum(f.guided_tours_revenue) from
fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where d.month_number=month(${today})
and  d.year4=year(${today}) 
and d.date_value <= ${today}) as mus_guided_tour_revenue_budget_mtd
,
(select sum(f.guided_tours_revenue) from
fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where d.year4=year(${today}) 
and d.date_value <= ${today}) as mus_guided_tour_revenue_budget_ytd
,
(select sum(early_access_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as early_access_tours
,
(select sum(early_access_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as early_access_tours_mtd
, 
(select sum(early_access_tours)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as early_access_tours_ytd
,
(select sum(early_access_tours) from 
fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value = ${today}) as early_access_tours_budget
,
(select sum(early_access_tours) from 
fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value) = year(${today})
and month(d.date_value) = month(${today})
and d.date_value <= ${today}) as early_access_tours_budget_mtd
,
(select sum(early_access_tours) from 
fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value)= year(${today})
and d.date_value <= ${today}) as early_access_tours_budget_ytd
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
,(select sum(early_access_tour_rev) from 
fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where  d.date_value = ${today}) as early_access_tour_revenue_budget
,
(select sum(early_access_tour_rev) from 
fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value) = year(${today})
and month(d.date_value) = month(${today})
and d.date_value <= ${today}) as early_access_tour_revenue_budget_mtd
,
(select sum(early_access_tour_rev) from 
fact_dpr_forecasts f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today}) as early_access_tour_revenue_budget_ytd
,
(select mem_mus_tours 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value = ${today})  as mem_mus_tours_budget
,
(select sum(mem_mus_tours)
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where  year(d.date_value) = year(${today})
and month(d.date_value) = month(${today})
and d.date_value <= ${today})  as mem_mus_tours_budget_mtd
,
(select sum(mem_mus_tours) 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today})  as mem_mus_tours_budget_ytd
,
(select mem_mus_tour_revenue 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where d.date_value = ${today})  as mem_mus_tour_revenue_budget
,
(select sum(mem_mus_tour_revenue)
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where  year(d.date_value) = year(${today})
and month(d.date_value) = month(${today})
and d.date_value <= ${today})  as mem_mus_tour_revenue_budget_mtd
,
(select sum(mem_mus_tour_revenue) 
from fact_forecasted_value_for_date f inner join  dim_date d on  f.key_date= d.date_key
where year(d.date_value) = year(${today})
and d.date_value <= ${today})  as mem_mus_tour_revenue_budget_ytd
,
(select sum(audio_tour_headset)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.date_value = ${today}) as audio_tour_headset
,
(select sum(audio_tour_headset)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.month_number = month(${today})
and d.date_value <= ${today} ) as audio_tour_headset_mtd
, 
(select sum(audio_tour_headset)
from
fact_dpr_report_data f 
inner join dim_date d on f.key_date = d.date_key
where d.year4 = year(${today}) 
and d.date_value <= ${today} ) as audio_tour_headset_ytd
,
(select audio_tour_headsets
from fact_dpr_forecasts f inner join dim_date d on f.key_date= d.date_key
where 
 d.date_value = ${today}) as audio_tour_headset_budget
,
(select sum(audio_tour_headsets)
from fact_dpr_forecasts f inner join dim_date d on f.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today}) as audio_tour_headset_budget_mtd
,
(select sum(audio_tour_headsets)
from fact_dpr_forecasts f inner join dim_date d on f.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as audio_tour_headset_budget_ytd
,
(select mem_audio_guide_revenue
from fact_dpr_forecasts f inner join dim_date d on f.key_date= d.date_key
where 
 d.date_value = ${today}) as mem_audio_guide_revenue_budget
,
(select sum(mem_audio_guide_revenue)
from fact_dpr_forecasts f inner join dim_date d on f.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today}) as mem_audio_guide_revenue_budget_mtd
,
(select sum(mem_audio_guide_revenue)
from fact_dpr_forecasts f inner join dim_date d on f.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as mem_audio_guide_revenue_budget_ytd

,
(select SUM(mem_audio_tour_headset)
from fact_dpr_report_data f inner join dim_date d on f.key_date= d.date_key
where d.date_value = ${today}) as mem_audio_guide_revenue
,
(select SUM(mem_audio_tour_headset)
from fact_dpr_report_data f inner join dim_date d on f.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today}) as mem_audio_guide_revenue_mtd
,
(select SUM(mem_audio_tour_headset)
from fact_dpr_report_data f inner join dim_date d on f.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as mem_audio_guide_revenue_ytd
,
(select SUM(youth_fam_tour_revenue)
from fact_dpr_report_data f inner join dim_date d on f.key_date= d.date_key
where d.date_value = ${today}) as youth_fam_tour_revenue
,
(select SUM(youth_fam_tour_revenue)
from fact_dpr_report_data f inner join dim_date d on f.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today}) as youth_fam_tour_revenue_mtd
,
(select SUM(youth_fam_tour_revenue)
from fact_dpr_report_data f inner join dim_date d on f.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as youth_fam_tour_revenue_ytd

,
(select cafe_revenue
from fact_dpr_forecasts f inner join dim_date d on f.key_date= d.date_key
where 
 d.date_value = ${today}) as mus_cafe1_revenue_budget
,
(select sum(cafe_revenue)
from fact_dpr_forecasts f inner join dim_date d on f.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.month_number=month(${today})
and d.date_value <= ${today}) as mus_cafe1_revenue_budget_mtd
,
(select sum(cafe_revenue)
from fact_dpr_forecasts f inner join dim_date d on f.key_date= d.date_key
where year(d.date_value)=year(${today}) 
and d.date_value <= ${today}) as mus_cafe1_revenue_budget_ytd
,
(select sum(box_office_mus_exit_don) 
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${today}) as box_office_mus_exit_don
,
(select sum(box_office_mus_exit_don) 
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}) as box_office_mus_exit_don_mtd
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
where year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}) as box_office_mem_don_mtd
,
(select sum(box_office_mem_don)
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value) = year(${today})
and d.date_value<= ${today}) as box_office_mem_don_ytd
,
(select sum(coatcheck_don)
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${today}) as coatcheck_don
,
(select sum(coatcheck_don)
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}) as coatcheck_don_mtd
,
(select sum(coatcheck_don)
from fact_donations_analysis_report f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value) = year(${today})
and d.date_value<= ${today}) as coatcheck_don_ytd
,
(select sum(coatcheck_donations)
from fact_dpr_forecasts f inner join dim_date d
on f.key_date=d.date_key
where d.date_value = ${today}) as coatcheck_donations_budget
,
(select sum(coatcheck_donations)
from fact_dpr_forecasts f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value) = year(${today})
and month(d.date_value)= month(${today})
and d.date_value<= ${today}) as coatcheck_donations_budget_mtd
,
(select sum(coatcheck_donations)
from fact_dpr_forecasts f inner join dim_date d
on f.key_date=d.date_key
where year(d.date_value) = year(${today})
and d.date_value<= ${today}) as coatcheck_donations_budget_ytd

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

-- ===== [datasources/sql-ds.xml] query: SameDateLastYear =====
select case when (((SELECT MOD(YEAR(${today}),4) = 0) AND (SELECT MOD(YEAR(${today}),100) != 0)) AND MONTH(${today}) = 2 AND DAY(${today}) = 29)
then CONCAT(YEAR(${today})-1,'02',EXTRACT(day from ${today})-1)
else CONCAT(YEAR(${today})-1,DATE_FORMAT(${today},'%m%d')) 
end as date_value