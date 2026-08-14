-- TRANSFORMATION: t_retail_cart_analysis_tabs
-- DESC: 

-- EXCEL OUT: /opt/pentaho/ops_reports/Retail Carts Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Retail Carts Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx


-- ===== STEP: Table input [TableInput] conn=911DW =====
SELECT
monthname(key_date),
dayname(key_date),
  key_date
, year(key_date) as year
, mem_visitors
, (mem_visitors - 0.25 * mem_visitors) as less_mem_visitors
, mus_visitors
, ((mem_visitors - 0.25 * mem_visitors) - mus_visitors) as less_mus_visitors
, mem_cart_customers
, case 
when year(key_date) = 2019 then mem_cart_customers/((mem_visitors - 0.25 * mem_visitors) - mus_visitors)
when year(key_date) = 2020 then mem_cart_customers/mem_visitors
end as mem_cart_capture_rate
, mem_cart_profit
, sales_mem_cart
, mem_cart_avg_sale
, case 
when year(key_date) = 2019 then mem_cart_profit/((mem_visitors - 0.25 * mem_visitors) - mus_visitors)
when year(key_date) = 2020 then mem_cart_profit/mem_visitors
end as profit_per_cap 
, case 
when year(key_date) = 2019 then sales_mem_cart/((mem_visitors - 0.25 * mem_visitors) - mus_visitors) 
when year(key_date) = 2020 then sales_mem_cart/mem_visitors
end as sales_per_cap 
FROM fact_retail_analysis
where ((key_date >= '2019-07-06' and key_date <= '2019-12-31')
or key_date >= '2020-07-04')
group by key_date