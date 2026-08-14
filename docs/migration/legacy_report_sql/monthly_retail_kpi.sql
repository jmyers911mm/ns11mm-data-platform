-- REPORT: Monthly Retail KPI (monthly_retail_kpi)

-- ===== [datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(year(key_date),' ','Actual') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name,(sum(f.ecom_sales)/sum(f.ecom_orders)) as avg_sale
from fact_retail_analysis f
where year(f.key_date) >='2015'
and f.key_date <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name, avg(avg_sale_ecom) as avg_sale 
from fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [datasources/sql-ds.xml] query: EcomSales =====
select CONCAT(year(key_date),' ','Actual') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name,(sum(f.ecom_sales)) as ecom_sale
from fact_retail_analysis f
where year(f.key_date) >='2015'
and f.key_date <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name, sum(total_sales_ecom) as ecom_sale 
from fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [datasources/sql-ds.xml] query: MusStoreCustomers =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , sum(store_customers)  as store_customers
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(mus_store_customers) as store_customers
from fact_retail_analysis
where year(key_date)>='2015'
and key_date <= ${today}
group by year(key_date), month(key_date))as A
group by the_year, the_month

UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, sum(store_customers) as store_customers
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(customers) as store_customers
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year, the_month

-- ===== [datasources/sql-ds.xml] query: MuseumAttendance =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , sum(mus_attendance)  as mus_attendance
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(mus_attendance) as mus_attendance
from fact_dpr_report_data f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))as A
group by the_year, the_month

UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, sum(mus_attendance) as mus_attendance
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(new_attendance) as mus_attendance
FROM fact_forecasted_value_for_date f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [datasources/sql-ds.xml] query: MusStoreVisitors =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , sum(store_visitors)  as store_visitors
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(mus_store_visitors) as store_visitors
from fact_retail_analysis
where year(key_date)>='2015'
and key_date <= ${today}
group by year(key_date), month(key_date))as A
group by the_year, the_month

UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, sum(store_visitors) as store_visitors
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(visitors) as store_visitors
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year, the_month

-- ===== [datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [datasources/sql-ds.xml] query: MemCartSales =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , sum(Sales) as Sales
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name,Sales 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(revenue) as Sales
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)*100
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [datasources/sql-ds.xml] query: MusStoreSales =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , sum(Sales)  as Sales 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))as A
group by the_year, the_month

UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Sales
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(revenue) as Sales
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport1/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport1/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport1/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
and d.date_value <= ${today}
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport1/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
and d.date_value <=${today}
group by year_format, month_number

-- ===== [subreport10/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport10/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport10/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport10/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport10/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport10/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport10/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport10/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport10/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport10/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport11/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport11/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport11/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport11/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport11/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport11/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport11/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport11/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport11/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport11/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport12/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport12/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport12/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport12/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport12/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport12/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport12/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport12/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport12/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport12/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport13/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport13/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport13/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport13/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport13/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport13/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport13/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport13/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport13/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport13/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport14/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,the_month, month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport14/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport14/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,the_month, month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport14/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport14/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport14/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport14/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport14/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport14/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport15/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport15/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport15/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport15/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport15/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport15/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport15/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport15/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport15/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport15/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport16/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(year(key_date),' ','Actual') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name,(sum(f.ecom_sales)/sum(f.ecom_orders)) as avg_sale
from fact_retail_analysis f
where year(f.key_date) >='2015'
and f.key_date <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name, avg(avg_sale_ecom) as avg_sale 
from fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport16/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport16/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport16/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport16/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport16/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport16/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport16/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport16/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport16/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport16/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport17/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport17/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport17/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport17/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport17/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport17/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport17/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport17/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport17/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport17/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport18/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport18/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport18/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport18/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport18/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport18/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport18/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport18/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport18/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport18/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport19/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport19/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
and d.date_value <= ${today}
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport19/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
and d.date_value <=${today}
group by year_format, month_number

-- ===== [subreport19/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport2/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport2/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
and d.date_value <= ${today}
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport2/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
and d.date_value <=${today}
group by year_format, month_number

-- ===== [subreport2/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport20/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport20/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport20/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport20/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport20/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport20/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport20/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport20/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport20/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport20/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport21/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport21/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
and d.date_value <= ${today}
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport21/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
and d.date_value <=${today}
group by year_format, month_number

-- ===== [subreport21/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport22/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(year(key_date),' ','Actual') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name,(sum(f.ecom_sales)/sum(f.ecom_orders)) as avg_sale
from fact_retail_analysis f
where year(f.key_date) >='2015'
and f.key_date <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name, avg(avg_sale_ecom) as avg_sale 
from fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport22/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport22/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport22/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport22/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport22/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport22/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport22/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport22/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport22/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport22/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport23/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(year(key_date),' ','Actual') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name,(sum(f.ecom_sales)/sum(f.ecom_orders)) as avg_sale
from fact_retail_analysis f
where year(f.key_date) >='2015'
and f.key_date <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name, avg(avg_sale_ecom) as avg_sale 
from fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport23/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport23/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport23/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport23/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport23/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport23/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport23/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport23/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport23/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport23/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport24/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(year(key_date),' ','Actual') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name,(sum(f.ecom_sales)/sum(f.ecom_orders)) as avg_sale
from fact_retail_analysis f
where year(f.key_date) >='2015'
and f.key_date <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name, avg(avg_sale_ecom) as avg_sale 
from fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport24/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport24/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport24/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport24/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport24/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport24/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport24/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport24/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport24/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport24/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport25/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport25/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport25/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
and d.date_value <= ${today}
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport25/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
and d.date_value <=${today}
group by year_format, month_number

-- ===== [subreport26/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport26/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport26/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport26/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport26/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport26/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport26/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport26/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport26/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport26/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport27/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(year(key_date),' ','Actual') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name,(sum(f.ecom_sales)/sum(f.ecom_orders)) as avg_sale
from fact_retail_analysis f
where year(f.key_date) >='2015'
and f.key_date <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name, avg(avg_sale_ecom) as avg_sale 
from fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport27/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport27/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport27/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport27/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport27/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport27/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport27/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport27/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport27/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport27/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport28/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(year(key_date),' ','Actual') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name,(sum(f.ecom_sales)/sum(f.ecom_orders)) as avg_sale
from fact_retail_analysis f
where year(f.key_date) >='2015'
and f.key_date <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name, avg(avg_sale_ecom) as avg_sale 
from fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport28/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport28/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport28/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport28/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport28/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport28/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport28/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport28/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport28/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport28/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport29/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(year(key_date),' ','Actual') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name,(sum(f.ecom_sales)/sum(f.ecom_orders)) as avg_sale
from fact_retail_analysis f
where year(f.key_date) >='2015'
and f.key_date <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name, avg(avg_sale_ecom) as avg_sale 
from fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport29/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport29/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport29/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport29/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport29/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport29/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport29/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport29/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport29/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport29/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport3/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (sum(sales)/sum(customers)) as avg_sale 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport3/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
and d.date_value <= ${today}
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport3/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
and d.date_value <=${today}
group by year_format, month_number

-- ===== [subreport3/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, avg(avg_sale) 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

-- ===== [subreport3/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
and d.date_value <=${today}
group by year(key_date), month(key_date)

-- ===== [subreport3/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport4/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport4/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport4/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
and d.date_value <= ${today}
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport4/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
and d.date_value <=${today}
group by year_format, month_number

-- ===== [subreport4/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, avg(avg_sale) 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

-- ===== [subreport4/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
and d.date_value <=${today}
group by year(key_date), month(key_date)

-- ===== [subreport4/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
and d.date_value <= ${today}
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport5/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport5/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport5/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
and d.date_value <= ${today}
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport5/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
and d.date_value <=${today}
group by year_format, month_number

-- ===== [subreport5/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, avg(avg_sale) 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

-- ===== [subreport5/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
and d.date_value <=${today}
group by year(key_date), month(key_date)

-- ===== [subreport5/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

-- ===== [subreport5/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
and d.date_value <= ${today}
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport5/subreport/datasources/sql-ds.xml] query: MemCartGrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <=${today}
group by year(key_date), month(key_date)

-- ===== [subreport6/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,the_month, month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname,the_month, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname,the_month

-- ===== [subreport6/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,the_month, month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname,the_month, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname,the_month

-- ===== [subreport6/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport6/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport6/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport6/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport6/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport6/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport6/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport6/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport7/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(year(key_date),' ','Actual') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name,(sum(f.ecom_sales)/sum(f.ecom_orders)) as avg_sale
from fact_retail_analysis f
where year(f.key_date) >='2015'
and f.key_date <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name, avg(avg_sale_ecom) as avg_sale 
from fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport7/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport7/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport7/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport7/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(the_year,' ','Actual') as final_yearname, the_month, month_name , avg(avg_sale) as AvgSale 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (avg(r.ecom_avg_sale)) as avg_sale
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, the_month, month_name, avg(avg_sale) as AvgSale
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, avg(budget_ecom_avg_sale) as avg_sale
FROM fact_retail_analysis f
where year(key_date)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name
order by final_yearname, the_month

-- ===== [subreport7/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport7/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport7/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport7/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport7/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport7/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport8/datasources/sql-ds.xml] query: MusStoreSales =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , sum(Sales)  as Sales 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))as A
group by the_year, the_month

UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Sales
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(revenue) as Sales
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport8/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport8/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport8/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport8/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(year(key_date),' ','Actual') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name,(sum(f.ecom_sales)/sum(f.ecom_orders)) as avg_sale
from fact_retail_analysis f
where year(f.key_date) >='2015'
and f.key_date <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name, avg(avg_sale_ecom) as avg_sale 
from fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport8/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport8/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport8/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport8/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport8/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport8/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport8/subreport/datasources/sql-ds.xml] query: MusStoreSales =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , sum(Sales)  as Sales 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))as A
group by the_year, the_month

UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Sales
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(revenue) as Sales
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport9/datasources/sql-ds.xml] query: MemCartSales =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , sum(Sales) as Sales
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name,Sales 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(revenue) as Sales
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport9/subreport/datasources/sql-ds.xml] query: EcomAvgSale =====
select CONCAT(year(key_date),' ','Actual') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name,(sum(f.ecom_sales)/sum(f.ecom_orders)) as avg_sale
from fact_retail_analysis f
where year(f.key_date) >='2015'
and f.key_date <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as final_yearname, month(key_date) as the_month, monthname(key_date) as month_name, avg(avg_sale_ecom) as avg_sale 
from fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport9/subreport/datasources/sql-ds.xml] query: GrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1003
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport9/subreport/datasources/sql-ds.xml] query: MemCartsGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Sales) - sum(Cost)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
union
select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name,0 as Sales, sum(f.Cost) as Cost
from fact_cogs f, dim_date d
where f.key_date = d.date_key
and f.key_facility= 1020
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
order by the_year,the_month)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_retail) as Profit
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport9/subreport/datasources/sql-ds.xml] query: EcomOrders =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(orders)) as Orders 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_orders)) as orders
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, orders
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(ecom_orders) as orders
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport9/subreport/datasources/sql-ds.xml] query: ConversionRate =====
select CONCAT(theyear,' ' ,'Actual') as the_year, month_number, the_month, (sum(customers)/sum(visitors))*100 as conversion_rate
FROM
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, sum(customers) as customers, 0 as visitors
from fact_profit_from_retail f, dim_date d
where f.key_date=d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and f.key_facility = 1007
group by year(key_date), month(key_date)
union
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as customers, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility = 1007
group by year(key_date), month(key_date))as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as month_number, monthname(key_date) as the_month, (avg(conversion_rate)*100) as conversion_rate
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)
order by the_year, month_number

-- ===== [subreport9/subreport/datasources/sql-ds.xml] query: MemCartSales =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , sum(Sales) as Sales
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1020
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
)A
group by the_year, the_month
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name,Sales 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(revenue) as Sales
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month

-- ===== [subreport9/subreport/datasources/sql-ds.xml] query: EcomGrossProfit =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , (sum(Profit)) as Profit 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.ecom_profit)) as Profit
from fact_retail_analysis r
where year(r.key_date)>='2015'
and r.key_date <= ${today}
group by year(key_date), month(key_date))as A
group by final_yearname, month_name
UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Profit
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(profit_from_ecom) as Profit
FROM fact_dpr_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by final_yearname,month_name

-- ===== [subreport9/subreport/datasources/sql-ds.xml] query: CaptureRate =====
select CONCAT(theyear,' ','Actual') as year_format, month_number, the_month, (sum(visitors)/sum(attendance))*100 as capture_rate 
from
(select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, 0 as attendance, sum(v.num_entry) as visitors
from fact_visitors v, dim_date d
where v.key_date = d.date_key
and year(d.date_value) >='2015'
and v.key_facility = 1007
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select year(key_date) as theyear, month(key_date) as month_number, monthname(key_date) as the_month, SUM(v.passes_scanned) as attendance, 0 as visitors
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and year(d.date_value) >='2015'
and d.date_value <= ${today}
and v.key_facility=1006
group by year(key_date), month(key_date)) as A
group by theyear, month_number
union
select CONCAT(year(f.key_date),' ','Budget') as year_format, month(key_date) as month_number, monthname(key_date) as the_month, AVG(capture_rate)
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and year(d.date_value) = year(${today})
group by year_format, month_number

-- ===== [subreport9/subreport/datasources/sql-ds.xml] query: AvgSale =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month,(sum(sales)/sum(customers)) as avg_sale
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale 
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport9/subreport/datasources/sql-ds.xml] query: GrossProfitPerCust =====
select CONCAT(year(key_date),' ','Actual') as the_year, month(key_date), monthname(key_date) as the_month, (profit/customers) as gp_per_cust 
from fact_profit_from_retail f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1007
and year(d.date_value) >='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date)
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, (profit_from_retail/customers) as gp_per_cust
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport9/subreport/datasources/sql-ds.xml] query: MemCartAvgSale =====
select CONCAT(the_year,' ','Actual') as the_year,the_month, the_monthname, (sum(Sales)/sum(Customers)) as avg_sale 
from 
(SELECT year(key_date) as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,(sum(r.Amount)+sum(r.Return_Amount)) as Sales, 0 as Customers
FROM 911dw.fact_retail r,  911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = r.key_facility
AND r.key_date = d.date_key
AND f.key_facility = 1020
AND r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
UNION
SELECT year(key_date)  as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname,0 as Sales, SUM(nt.Num_Tickets) as Customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1020
AND year(d.date_value)>='2015'
and d.date_value <=${today}
group by the_year, the_month
)as A
group by the_year, the_month
UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date), monthname(key_date) as the_month, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
and d.date_value <= ${today}
group by year(key_date), month(key_date)

UNION
select CONCAT(year(key_date),' ','Budget') as the_year, month(key_date) as the_month, monthname(key_date) as the_monthname, avg(average_sale) as avg_sale
from fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1020
and year(d.date_value) = year(${today})
group by year(key_date), month(key_date)

-- ===== [subreport9/subreport/datasources/sql-ds.xml] query: MusStoreSales =====
select CONCAT(the_year,' ','Actual') as final_yearname,month_name , sum(Sales)  as Sales 
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, (sum(r.Amount) + sum(r.Return_Amount)) as Sales, 0 as Cost
from fact_retail r, dim_date d
where r.key_date = d.date_key
and r.key_facility = 1003
and r.key_summary_category <> '6'
and r.key_item_descr not in ('2449','2450','2451','2452','2453','2454')
and year(d.date_value)>='2015'
and d.date_value <= ${today}
group by year(key_date), month(key_date))as A
group by the_year, the_month

UNION
select CONCAT(the_year,' ','Budget') as final_yearname, month_name, Sales
from
(select year(key_date) as the_year, month(key_date) as the_month,monthname(key_date) as month_name, sum(revenue) as Sales
FROM fact_retail_forecasts f, dim_date d
where f.key_date = d.date_key
and f.key_facility = 1003
and year(d.date_value)= year (${today})
group by year(key_date), the_month
order by year(key_date), the_month) as A
group by the_year,the_month