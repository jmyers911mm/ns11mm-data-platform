-- TRANSFORMATION: t_retail_analysis_tabs_bk
-- DESC: 

-- EXCEL OUT: /opt/pentaho/ops_reports/Retail Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Retail Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Retail Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Retail Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Retail Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Retail Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Retail Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Retail Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Retail Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx


-- ===== STEP: Table input [TableInput] conn=911DW =====
SELECT
monthname(key_date),
dayname(key_date),
  key_date
, year(key_date) as year
, mus_visitors
, mus_store_visitors
, budget_mus_store_visitors
, ms_visitors_diff
, ms_capture_rate
, budget_ms_capture_rate
, ms_capture_rate_diff
, mus_store_customers
, budget_mus_store_customers
, ms_customers_diff
, ms_conversion_rate
, budget_ms_conversion_rate
, ms_conversion_rate_diff
, sales_mus_store
, cost_mus_store
, profit_mus_store
, budget_profit_mus_store
, profit_mus_store_diff
, mus_store_avg_sale
, budget_mus_store_avg_sale
, mus_store_avg_sale_diff
, mus_store_profit_per_cust
, vesey_visitors
, budget_vesey_visitors
, vesey_visitors_diff
, vesey_customers
, budget_vesey_customers
, vesey_customers_diff
, vesey_conversion_rate
, budget_vesey_conversion_rate
, vesey_conversion_rate_diff
, profit_vesey
, budget_profit_vesey
, profit_vesey_diff
, vesey_avg_sale
, budget_vesey_avg_sale
, vesey_avg_sale_diff
, profit_per_cust_vesey
, ecom_orders
, budget_ecom_orders
, ecom_orders_diff
, ecom_sales
, ecom_avg_sale
, budget_ecom_avg_sale
, ecom_avg_sale_diff
, ecom_profit_per_order
, ecom_profit
, budget_ecom_profit
, ecom_profit_diff
, mem_visitors
, mem_cart_customers
, budget_mem_cart_customers
, mem_cart_customers_diff
, mem_cart_capture_rate
, mem_cart_profit_per_cust
, mem_cart_profit
, budget_mem_cart_profit
, mem_cart_profit_diff
, mem_cart_avg_sale
, budget_mem_cart_avg_sale
, mem_cart_avg_sale_diff
FROM fact_retail_analysis
order by key_date