-- REPORT: Today's Sales Report (hourly_retail_report)

-- ===== [datasources/sql-ds.xml] query: Cart 1 =====
select if(hourofday < 12, 
    concat(cast(hourofday as char) , 'AM - ', cast(hourofday+1 as char), if(hourofday+1 >11,'PM', 'AM')),
    concat(cast(if(hourofday-12<1, 12, hourofday - 12) as char), 'PM - ' , cast(hourofday-11 as char), if(hourofday+1 >23,'AM', 'PM'))) as byhour, 
    sum(sales), sum(profit), sum(avg_sale), sum(tkt_count),sum(qty), sum(totes_qty), sum(avg_qty), sum(totes_qty)/sum(tkt_count) as avg_tote_qty
from
(select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, sum(sales) as sales, sum(sales)-sum(cost) as profit, sum(sales)/count(distinct doc_id) as avg_sale, 
 count(distinct doc_id) as tkt_count, sum(qty_sold) as qty, 0 as totes_qty, (sum(qty_sold)/count(distinct doc_id)) as avg_qty
 from fact_todays_retail_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and store_id = 11
group by tkt_hour
UNION
select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 
 0 as tkt_count, 0 as qty, sum(qty_sold) as totes_qty, 0 as avg_qty
 from fact_todays_retail_product_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and str_id = 11
and item_no in ('101423','101424','101425','101470','200314','200388', '200569','200570','200747','200868','200869','200870','200868','200869','200870','201114','201206')
group by tkt_hour
) as A
where ( hourofday>='8')
and hourofday < fn_CurTime()
group by hourofday

-- ===== [datasources/sql-ds.xml] query: Store 8 =====
select if(hourofday < 12, 
    concat(cast(hourofday as char) , 'AM - ', cast(hourofday+1 as char), if(hourofday+1 >11,'PM', 'AM')),
    concat(cast(if(hourofday-12<1, 12, hourofday - 12) as char), 'PM - ' , cast(hourofday-11 as char), if(hourofday+1 >23,'AM', 'PM'))) as byhour, 
    sum(sales), sum(profit), sum(avg_sale), sum(tkt_count), sum(qty),sum(totes_qty), sum(avg_qty), sum(totes_qty)/sum(tkt_count) as avg_tote_qty,
    sum(mus_visitors) as mus_visitors, sum(tkt_count)/sum(mus_visitors) as cafe_conversion_rate
from
(select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, sum(sales) as sales, sum(sales)-sum(cost) as profit, sum(sales)/count(distinct doc_id) as avg_sale, 
 count(distinct doc_id) as tkt_count,sum(qty_sold) as qty,0 as totes_qty,  (sum(qty_sold)/count(distinct doc_id)) as avg_qty
 from fact_todays_retail_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and store_id = 1
group by tkt_hour
union
select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 
 0 as tkt_count, 0 as qty, sum(qty_sold) as totes_qty, 0 as avg_qty
 from fact_todays_retail_product_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and str_id = 1
and item_no in ('101423','101424','101425','101470','200314','200388', '200569','200570','200747','200868','200869','200870','201206')
group by tkt_hour
UNION
select f.hourofday, sum(f.passes_scanned) as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 
 0 as tkt_count, 0 as qty, 0 as totes_qty, 0 as avg_qty
from fact_visitors_hourly f, dim_date d
where f.key_date=d.date_key
and d.date_value = ${today}
and f.key_facility in ( 1006,3000)
group by f.hourofday
) as A
where ( hourofday>='8')
and hourofday < fn_CurTime()
group by hourofday

-- ===== [datasources/sql-ds.xml] query: Cart 3 =====
select if(hourofday < 12, 
    concat(cast(hourofday as char) , 'AM - ', cast(hourofday+1 as char), if(hourofday+1 >11,'PM', 'AM')),
    concat(cast(if(hourofday-12<1, 12, hourofday - 12) as char), 'PM - ' , cast(hourofday-11 as char), if(hourofday+1 >23,'AM', 'PM'))) as byhour, 
    sum(sales), sum(profit), sum(avg_sale), sum(tkt_count),sum(qty), sum(totes_qty), sum(avg_qty), sum(totes_qty)/sum(tkt_count) as avg_tote_qty
from
(select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, sum(sales) as sales, sum(sales)-sum(cost) as profit, sum(sales)/count(distinct doc_id) as avg_sale, 
 count(distinct doc_id) as tkt_count, sum(qty_sold) as qty, 0 as totes_qty, (sum(qty_sold)/count(distinct doc_id)) as avg_qty
 from fact_todays_retail_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and store_id = 13
group by tkt_hour
UNION
select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 
 0 as tkt_count, 0 as qty, sum(qty_sold) as totes_qty, 0 as avg_qty
 from fact_todays_retail_product_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and str_id = 13
and item_no in ('101423','101424','101425','101470','200314','200388', '200569','200570','200747','200868','200869','200870','201114','201206')
group by tkt_hour
) as A
where (hourofday>='8')
and hourofday < fn_CurTime()
group by hourofday

-- ===== [datasources/sql-ds.xml] query: Cart 2 =====
select if(hourofday < 12, 
    concat(cast(hourofday as char) , 'AM - ', cast(hourofday+1 as char), if(hourofday+1 >11,'PM', 'AM')),
    concat(cast(if(hourofday-12<1, 12, hourofday - 12) as char), 'PM - ' , cast(hourofday-11 as char), if(hourofday+1 >23,'AM', 'PM'))) as byhour, 
    sum(sales), sum(profit), sum(avg_sale), sum(tkt_count), sum(qty),sum(totes_qty), sum(avg_qty), sum(totes_qty)/sum(tkt_count) as avg_tote_qty
from
(select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, sum(sales) as sales, sum(sales)-sum(cost) as profit, sum(sales)/count(distinct doc_id) as avg_sale, 
 count(distinct doc_id) as tkt_count,sum(qty_sold) as qty,0 as totes_qty,  (sum(qty_sold)/count(distinct doc_id)) as avg_qty
 from fact_todays_retail_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and store_id = 12
group by tkt_hour
union
select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 
 0 as tkt_count, 0 as qty, sum(qty_sold) as totes_qty, 0 as avg_qty
 from fact_todays_retail_product_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and str_id = 12
and item_no in ('101423','101424','101425','101470','200314','200388', '200569','200570','200747','200868','200869','200870','201114','201206')
group by tkt_hour
) as A
where ( hourofday>='8')
and hourofday < fn_CurTime()
group by hourofday

-- ===== [datasources/sql-ds.xml] query: Cart 4 =====
select if(hourofday < 12, 
    concat(cast(hourofday as char) , 'AM - ', cast(hourofday+1 as char), if(hourofday+1 >11,'PM', 'AM')),
    concat(cast(if(hourofday-12<1, 12, hourofday - 12) as char), 'PM - ' , cast(hourofday-11 as char), if(hourofday+1 >23,'AM', 'PM'))) as byhour, 
    sum(sales), sum(profit), sum(avg_sale), sum(tkt_count),sum(qty), sum(totes_qty), sum(avg_qty), sum(totes_qty)/sum(tkt_count) as avg_tote_qty,
    sum(mus_visitors) as mus_visitors, sum(totes_qty)/sum(mus_visitors) as musag_conversion_rate
from
(select f.tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, sum(f.sales) as sales, sum(f.sales)-sum(f.cost) as profit, sum(f.sales)/count(distinct f.doc_id) as avg_sale, 
 count(distinct f.doc_id) as tkt_count, sum(f.qty_sold) as qty, 0 as totes_qty, (sum(f.qty_sold)/count(distinct f.doc_id)) as avg_qty
 from fact_todays_retail_data f, dim_date d, fact_todays_retail_product_data p 
where date(f.key_date)=d.date_value and f.doc_id=p.doc_id and f.tkt_hour=p.tkt_hour
and d.date_value = ${today}
and f.store_id = 14 
and p.item_no in ('201197')
group by f.tkt_hour
UNION
select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 
 0 as tkt_count, 0 as qty, sum(qty_sold) as totes_qty, 0 as avg_qty
 from fact_todays_retail_product_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and str_id = 14
and item_no in ('101423','101424','101425','101470','200314','200388', '200569','200570','200747','200868','200869','200870','201197')
group by tkt_hour
UNION
select f.hourofday, sum(f.passes_scanned) as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 
 0 as tkt_count, 0 as qty, 0 as totes_qty, 0 as avg_qty
from fact_visitors_hourly f, dim_date d
where f.key_date=d.date_key
and d.date_value = ${today}
and f.key_facility in ( 1006,3000)
group by f.hourofday
) as A
where (hourofday>='8')
and hourofday < fn_CurTime()
group by hourofday

-- ===== [datasources/sql-ds.xml] query: Museum Store =====
select if(hourofday < 12, 
    concat(cast(hourofday as char) , 'AM - ', cast(hourofday+1 as char), if(hourofday+1 >11,'PM', 'AM')),
    concat(cast(if(hourofday-12<1, 12, hourofday - 12) as char), 'PM - ' , cast(hourofday-11 as char), if(hourofday+1 >23,'AM', 'PM'))) as byhour, 
    sum(sales), sum(profit), sum(avg_sale), sum(qty), sum(tote_qty), sum(tkt_count), sum(avg_qty), sum(tkt_count)/sum(mus_store_visitors) as conversion_rate, 
    sum(mus_store_visitors), sum(mus_visitors),
sum(mus_store_visitors)/sum(mus_visitors) as capture_rate, (sum(tote_qty)/sum(tkt_count)) as avg_tote_qty
from
(select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, sum(sales) as sales, sum(sales)-sum(cost) as profit, sum(sales)/count(distinct doc_id) as avg_sale, 
sum(qty_sold) as qty, 0 as tote_qty,count(distinct doc_id) as tkt_count, sum(qty_sold)/count(distinct doc_id) as avg_qty
 from fact_todays_retail_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and store_id = 9
group by tkt_hour
UNION
select hourofday, sum(passes_scanned) as mus_visitors, 0 as mus_store_visitors , 0 as sales, 0 as profit, 0 as avg_sale, 0 as qty,0 as tote_qty, 0 as tkt_count, 0 as avg_qty
from fact_visitors_hourly f, dim_date d
where f.key_date=d.date_key
and d.date_value = ${today}
and f.key_facility in ( 1006,3000)
group by hourofday
UNION
SELECT hourofday, 0 as mus_visitors, SUM(v.num_entry) as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 0 as qty, 0 as tote_qty, 0 as tkt_count, 0 as avg_qty
  FROM fact_visitors_hourly v, 911dw.dim_date d
  WHERE v.key_date = d.date_key
  AND v.key_facility = 1007
  AND d.date_value = ${today}
group by hourofday
union
select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 0 as qty, sum(qty_sold) as tote_qty,
0 as tkt_count, 0 as avg_qty 
 from fact_todays_retail_product_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and item_no in ('101423','101424','101425','101470','200314','200388', '200569','200570','200747','200868','200869','200870','201206')
and str_id = 9
group by tkt_hour) as A
where ( hourofday>='8')
and hourofday < fn_CurTime()
group by hourofday

-- ===== [datasources/sql-ds.xml] query: Totals =====
select if(hourofday < 12, 
    concat(cast(hourofday as char) , 'AM - ', cast(hourofday+1 as char), if(hourofday+1 >11,'PM', 'AM')),
    concat(cast(if(hourofday-12<1, 12, hourofday - 12) as char), 'PM - ' , cast(hourofday-11 as char), if(hourofday+1 >23,'AM', 'PM'))) as byhour, 
    sum(sales), sum(profit), sum(avg_sale), sum(tkt_count),sum(qty), sum(totes_qty), sum(avg_qty), sum(totes_qty)/sum(tkt_count) as avg_tote_qty
from
(select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, sum(sales) as sales, sum(sales)-sum(cost) as profit, sum(sales)/count(distinct doc_id) as avg_sale, 
 count(distinct doc_id) as tkt_count, sum(qty_sold) as qty, 0 as totes_qty, (sum(qty_sold)/count(distinct doc_id)) as avg_qty
 from fact_todays_retail_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and store_id in (11,12,13)
group by tkt_hour
UNION
select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 
 0 as tkt_count, 0 as qty, sum(qty_sold) as totes_qty, 0 as avg_qty
 from fact_todays_retail_product_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and str_id in (11,12,13)
and item_no in ('200569','101423','101424','101425','101470','200314','200388','200569','200570','200747','200868','200869','200870','201114','201206')
group by tkt_hour
) as A
where (hourofday>='8')
and hourofday < fn_CurTime()
group by hourofday

-- ===== [subreport3/datasources/sql-ds.xml] query: Cart 1 =====
select if(hourofday < 12, 
    concat(cast(hourofday as char) , 'AM - ', cast(hourofday+1 as char), if(hourofday+1 >11,'PM', 'AM')),
    concat(cast(if(hourofday-12<1, 12, hourofday - 12) as char), 'PM - ' , cast(hourofday-11 as char), if(hourofday+1 >23,'AM', 'PM'))) as byhour, 
    sum(sales), sum(profit), sum(avg_sale), sum(tkt_count),sum(qty), sum(totes_qty), sum(avg_qty), sum(totes_qty)/sum(tkt_count) as avg_tote_qty
from
(select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, sum(sales) as sales, sum(sales)-sum(cost) as profit, sum(sales)/count(distinct doc_id) as avg_sale, 
 count(distinct doc_id) as tkt_count, sum(qty_sold) as qty, 0 as totes_qty, (sum(qty_sold)/count(distinct doc_id)) as avg_qty
 from fact_todays_retail_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and store_id = 11
group by tkt_hour
UNION
select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 
 0 as tkt_count, 0 as qty, sum(qty_sold) as totes_qty, 0 as avg_qty
 from fact_todays_retail_product_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and str_id = 11
and item_no in ('101423','101424','101425','101470','200314','200388', '200569','200570','200747','200868','200869','200870','201114','201206')
group by tkt_hour
) as A
where ( hourofday>='8')
and hourofday < fn_CurTime()
group by hourofday

-- ===== [subreport3/datasources/sql-ds.xml] query: Store 8 =====
select if(hourofday < 12, 
    concat(cast(hourofday as char) , 'AM - ', cast(hourofday+1 as char), if(hourofday+1 >11,'PM', 'AM')),
    concat(cast(if(hourofday-12<1, 12, hourofday - 12) as char), 'PM - ' , cast(hourofday-11 as char), if(hourofday+1 >23,'AM', 'PM'))) as byhour, 
    sum(sales), sum(profit), sum(avg_sale), sum(tkt_count), sum(qty),sum(totes_qty), sum(avg_qty), sum(totes_qty)/sum(tkt_count) as avg_tote_qty,
    sum(mus_visitors) as mus_visitors, sum(tkt_count)/sum(mus_visitors) as cafe_conversion_rate
from
(select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, sum(sales) as sales, sum(sales)-sum(cost) as profit, sum(sales)/count(distinct doc_id) as avg_sale, 
 count(distinct doc_id) as tkt_count,sum(qty_sold) as qty,0 as totes_qty,  (sum(qty_sold)/count(distinct doc_id)) as avg_qty
 from fact_todays_retail_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and store_id = 1
group by tkt_hour
union
select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 
 0 as tkt_count, 0 as qty, sum(qty_sold) as totes_qty, 0 as avg_qty
 from fact_todays_retail_product_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and str_id = 1
and item_no in ('101423','101424','101425','101470','200314','200388', '200569','200570','200747','200868','200869','200870','201083','201206')
group by tkt_hour
UNION
select f.hourofday, sum(f.passes_scanned) as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 
 0 as tkt_count, 0 as qty, 0 as totes_qty, 0 as avg_qty
from fact_visitors_hourly f, dim_date d
where f.key_date=d.date_key
and d.date_value = ${today}
and f.key_facility in ( 1006,3000)
group by f.hourofday
) as A
where ( hourofday>='8')
and hourofday < fn_CurTime()
group by hourofday

-- ===== [subreport3/datasources/sql-ds.xml] query: Cart 3 =====
select if(hourofday < 12, 
    concat(cast(hourofday as char) , 'AM - ', cast(hourofday+1 as char), if(hourofday+1 >11,'PM', 'AM')),
    concat(cast(if(hourofday-12<1, 12, hourofday - 12) as char), 'PM - ' , cast(hourofday-11 as char), if(hourofday+1 >23,'AM', 'PM'))) as byhour, 
    sum(sales), sum(profit), sum(avg_sale), sum(tkt_count),sum(qty), sum(totes_qty), sum(avg_qty), sum(totes_qty)/sum(tkt_count) as avg_tote_qty
from
(select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, sum(sales) as sales, sum(sales)-sum(cost) as profit, sum(sales)/count(distinct doc_id) as avg_sale, 
 count(distinct doc_id) as tkt_count, sum(qty_sold) as qty, 0 as totes_qty, (sum(qty_sold)/count(distinct doc_id)) as avg_qty
 from fact_todays_retail_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and store_id = 13
group by tkt_hour
UNION
select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 
 0 as tkt_count, 0 as qty, sum(qty_sold) as totes_qty, 0 as avg_qty
 from fact_todays_retail_product_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and str_id = 13
and item_no in ('101423','101424','101425','101470','200314','200388', '200569','200570','200747','200868','200869','200870','201114')
group by tkt_hour
) as A
where (hourofday>='8')
and hourofday < fn_CurTime()
group by hourofday

-- ===== [subreport3/datasources/sql-ds.xml] query: Cart 2 =====
select if(hourofday < 12, 
    concat(cast(hourofday as char) , 'AM - ', cast(hourofday+1 as char), if(hourofday+1 >11,'PM', 'AM')),
    concat(cast(if(hourofday-12<1, 12, hourofday - 12) as char), 'PM - ' , cast(hourofday-11 as char), if(hourofday+1 >23,'AM', 'PM'))) as byhour, 
    sum(sales), sum(profit), sum(avg_sale), sum(tkt_count), sum(qty),sum(totes_qty), sum(avg_qty), sum(totes_qty)/sum(tkt_count) as avg_tote_qty
from
(select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, sum(sales) as sales, sum(sales)-sum(cost) as profit, sum(sales)/count(distinct doc_id) as avg_sale, 
 count(distinct doc_id) as tkt_count,sum(qty_sold) as qty,0 as totes_qty,  (sum(qty_sold)/count(distinct doc_id)) as avg_qty
 from fact_todays_retail_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and store_id = 12
group by tkt_hour
union
select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 
 0 as tkt_count, 0 as qty, sum(qty_sold) as totes_qty, 0 as avg_qty
 from fact_todays_retail_product_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and str_id = 12
and item_no in ('101423','101424','101425','101470','200314','200388', '200569','200570','200747','200868','200869','200870','201114')
group by tkt_hour
) as A
where ( hourofday>='8')
and hourofday < fn_CurTime()
group by hourofday

-- ===== [subreport3/datasources/sql-ds.xml] query: Museum Store =====
select if(hourofday < 12, 
    concat(cast(hourofday as char) , 'AM - ', cast(hourofday+1 as char), if(hourofday+1 >11,'PM', 'AM')),
    concat(cast(if(hourofday-12<1, 12, hourofday - 12) as char), 'PM - ' , cast(hourofday-11 as char), if(hourofday+1 >23,'AM', 'PM'))) as byhour, 
    sum(sales), sum(profit), sum(avg_sale), sum(qty), sum(tote_qty), sum(tkt_count), sum(avg_qty), sum(tkt_count)/sum(mus_store_visitors) as conversion_rate, 
    sum(mus_store_visitors), sum(mus_visitors),
sum(mus_store_visitors)/sum(mus_visitors) as capture_rate, (sum(tote_qty)/sum(tkt_count)) as avg_tote_qty
from
(select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, sum(sales) as sales, sum(sales)-sum(cost) as profit, sum(sales)/count(distinct doc_id) as avg_sale, 
sum(qty_sold) as qty, 0 as tote_qty,count(distinct doc_id) as tkt_count, sum(qty_sold)/count(distinct doc_id) as avg_qty
 from fact_todays_retail_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and store_id = 9
group by tkt_hour
UNION
select hourofday, sum(passes_scanned) as mus_visitors, 0 as mus_store_visitors , 0 as sales, 0 as profit, 0 as avg_sale, 0 as qty,0 as tote_qty, 0 as tkt_count, 0 as avg_qty
from fact_visitors_hourly f, dim_date d
where f.key_date=d.date_key
and d.date_value = ${today}
and f.key_facility in ( 1006,3000)
group by hourofday
UNION
SELECT hourofday, 0 as mus_visitors, SUM(v.num_entry) as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 0 as qty, 0 as tote_qty, 0 as tkt_count, 0 as avg_qty
  FROM fact_visitors_hourly v, 911dw.dim_date d
  WHERE v.key_date = d.date_key
  AND v.key_facility = 1007
  AND d.date_value = ${today}
group by hourofday
union
select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 0 as qty, sum(qty_sold) as tote_qty,
0 as tkt_count, 0 as avg_qty 
 from fact_todays_retail_product_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and item_no in ('101423','101424','101425','101470','200314','200388', '200569','200570','200747','200868','200869','200870')
and str_id = 9
group by tkt_hour) as A
where ( hourofday>='8')
and hourofday < fn_CurTime()
group by hourofday

-- ===== [subreport3/datasources/sql-ds.xml] query: Totals =====
select if(hourofday < 12, 
    concat(cast(hourofday as char) , 'AM - ', cast(hourofday+1 as char), if(hourofday+1 >11,'PM', 'AM')),
    concat(cast(if(hourofday-12<1, 12, hourofday - 12) as char), 'PM - ' , cast(hourofday-11 as char), if(hourofday+1 >23,'AM', 'PM'))) as byhour, 
    sum(sales), sum(profit), sum(avg_sale), sum(tkt_count),sum(qty), sum(totes_qty), sum(avg_qty), sum(totes_qty)/sum(tkt_count) as avg_tote_qty
from
(select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, sum(sales) as sales, sum(sales)-sum(cost) as profit, sum(sales)/count(distinct doc_id) as avg_sale, 
 count(distinct doc_id) as tkt_count, sum(qty_sold) as qty, 0 as totes_qty, (sum(qty_sold)/count(distinct doc_id)) as avg_qty
 from fact_todays_retail_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and store_id in (11,12,13)
group by tkt_hour
UNION
select tkt_hour as hourofday, 0 as mus_visitors, 0 as mus_store_visitors, 0 as sales, 0 as profit, 0 as avg_sale, 
 0 as tkt_count, 0 as qty, sum(qty_sold) as totes_qty, 0 as avg_qty
 from fact_todays_retail_product_data f, dim_date d 
where date(key_date)=d.date_value
and d.date_value = ${today}
and str_id in (11,12,13)
and item_no in ('101423','101424','101425','101470','200314','200388', '200569','200570','200747','200868','200869','200870')
group by tkt_hour
) as A
where (hourofday>='8')
and hourofday < fn_CurTime()
group by hourofday