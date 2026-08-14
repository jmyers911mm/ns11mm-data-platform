-- TRANSFORMATION: t_website_commerce_report_excel_recurring
-- DESC: 

-- EXCEL OUT: /opt/pentaho/ops_reports/Website Commerce Report - Recurring tmpl=template.xls
-- EXCEL OUT: /opt/pentaho/ops_reports/Website Commerce Report - Recurring tmpl=template.xls
-- EXCEL OUT: /opt/pentaho/ops_reports/Website Commerce Report - Recurring tmpl=template.xls
-- EXCEL OUT: /opt/pentaho/ops_reports/Website Commerce Report - Recurring tmpl=template.xls


-- ===== STEP: ti: Website Commerce Report - By month [TableInput] conn=911DW =====
select Month, 
sum(don_prev) as 'Donation Revenue - 2020',
sum(mem_prev) as 'Membership Revenue - 2020', 
sum(don_current) as 'Donation Revenue - 2021',
sum(mem_current) as 'Membership Revenue - 2021'
from
(select 
monthname(date_created) as Month, month(date_created) as month_number,
sum(case when sku like '%donat%' and year(date_created)=2020 then revenue else 0 end) as don_prev,
sum( case when sku like '%membership%' and year(date_created)=2020 then revenue else 0 end) as mem_prev,
0 as don_current,
0 as mem_current 
 from fact_website_data_d8
where year(date_created) >=year(?)-1
and month(date_created) <= month(?)
and date_created <= CONCAT(year(?)-1,DATE_FORMAT(?,'%m'),DATE_FORMAT(?,'%d'))
group by month(date_created)
UNION
select monthname(date_created) as Month, month(date_created) as month_number,
0 as don_prev,
0 as mem_prev, 
sum(case when sku like '%donat%' and year(date_created)=2021 then revenue else 0 end) as don_current,
sum( case when sku like '%membership%' and year(date_created)=2021 then revenue else 0 end) as  mem_current
from fact_website_data_d8
where year(date_created) = year(?)
and month(date_created) <= month(?)
group by month_number) as A
group by month_number

-- ===== STEP: ti: Website Commerce Report - By Date [TableInput] conn=911DW =====
select DATE_FORMAT(date_key,'%Y-%m-%d') as Date, 
case when null then 0 else (sum(case when sku like '%donat%' then revenue else 0 end)) end as 'Donation Revenue',
case when null then 0 else (sum(case when sku like '%membership%' then revenue else 0 end)) end as 'Membership Revenue'
from fact_website_data_d8 f right join dim_date d
on f.date_created = d.date_key
where year(d.date_key) = year(?)
and month(d.date_key) = month(?)
and d.date_key <= ?
group by d.date_key

-- ===== STEP: ti: Website Commerce Report - Donation By Date [TableInput] conn=911DW =====
select DATE_FORMAT(date_created,'%Y-%m-%d') as Date,
title,
sum(quantity),
sum(revenue)
from fact_website_data_d8
where sku like '%donat%' 
and date_created = ?
group by order_id

-- ===== STEP: ti: Website Commerce Report - Recurring by month [TableInput] conn=911DW =====
select Month, 
sum(don_2019) as 'Donation Revenue - 2019',
sum(mem_2019) as 'Membership Revenue - 2019', 
sum(don_2020) as 'Donation Revenue - 2020',
sum(mem_2020) as 'Membership Revenue - 2020'
from
(select 
monthname(date_completed) as Month, month(date_completed) as month_number,
sum(case when sku like '%donat%' and year(date_completed)=2019 then revenue else 0 end) as don_2019,
sum( case when sku like '%renewal-%' and year(date_completed)=2019 then revenue else 0 end) as mem_2019,
0 as don_2020,
0 as mem_2020 
 from fact_website_recurring_data_d8
where year(date_completed) >=year(?)-1
and month(date_completed) <= month(?)
and date_completed <= CONCAT(year(?)-1,DATE_FORMAT(?,'%m'),DATE_FORMAT(?,'%d'))
group by month(date_completed)
UNION
select monthname(date_completed) as Month, month(date_completed) as month_number,
0 as don_2019,
0 as mem_2019, 
sum(case when sku like '%donat%' and year(date_completed)=2020 then revenue else 0 end) as don_2020,
sum( case when sku like '%renewal-%' and year(date_completed)=2020 then revenue else 0 end) as  mem_2020
from fact_website_recurring_data_d8
where year(date_completed) = year(?)
and month(date_completed) <= month(?)
group by month_number) as A
group by month_number