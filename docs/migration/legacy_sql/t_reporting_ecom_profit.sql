-- TRANSFORMATION: t_reporting_ecom_profit
-- DESC: 

-- WRITES: 911DW:.fact_dpr_report_data (InsertUpdate)


-- ===== STEP: Shopify Cost [TableInput] conn=911DW =====
select key_date, sum(cost) as subtract_from_total
from fact_shopify_cost_values f inner join dim_date d on f.key_date=d.date_key
where d.date_value < '20170701'
group by key_date

-- ===== STEP: ti: Ecommerce Sales before Shopify [TableInput] conn=911DW =====
select e.key_date as key_date, (0.66* sum(e.Total_Revenue)) as ecom_sales
from fact_ecommerce_2 e inner join  dim_date d on e.key_date = d.date_key
where
e.key_category <> 6 
and e.key_item_description not in(3368,3367,3369,3370,3371,3385,2935)
group by key_date

-- ===== STEP: ti: Ecommerce Sales from Counterpoint(synced from Shopify) [TableInput] conn=911DW =====
select r.key_date as key_date, (sum(r.Amount)+sum(r.Return_Amount)) as ecom_sales
 from
fact_retail r inner join dim_date d on r.key_date = d.date_key
where r.key_facility = 1234
and r.key_summary_category <> 6
and d.date_value >= '20170701'
group by key_date

-- ===== STEP: ti: Ecommerce Sales from Shopify [TableInput] conn=911DW =====
select o.key_date as key_date, (sum(total_revenue) - IFNULL(sum(total_refund),0)) as ecom_sales
from fact_shopify_orders o inner join dim_date d on o.key_date=d.date_key
where d.date_value < '20170701'
group by key_date

-- ===== STEP: ti: Ecommerce cost from Counterpoint [TableInput] conn=911DW =====
select f.key_date,sum(f.Cost)  as subtract_from_total
from fact_cogs f inner join dim_date d on f.key_date=d.date_key
where f.key_facility = 1234
and d.date_value >= '20170701'
group by key_date

-- ===== STEP: ti: Get the dates from dimension table [TableInput] conn=911DW =====
select date_key from dim_date
where date_key >= '20110501'
and date_key <= ?

-- ===== STEP: ti: Shopify Discount [TableInput] conn=911DW =====
select key_date, ifnull(sum(total_discount),0) as subtract_from_total
from fact_shopify_discounts di inner join dim_date d on di.key_date=d.date_key
where d.date_value >= '20160301'
and d.date_value < '20170701'
group by key_date