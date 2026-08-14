-- TRANSFORMATION: t_mus_store_analysis_excel
-- DESC: 

-- EXCEL OUT: /opt/pentaho/ops_reports/Museum Store Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx


-- ===== STEP: Table input [TableInput] conn=911DW =====
SELECT
  key_date
, mus_visitors
, mus_store_visitors
, conversion_rate
, mus_store_customers
, sales_mus_store
, cost_mus_store
, profit_mus_store
, mus_store_avg_sale
, mus_store_profit_per_cust
, capture_rate
, ecom_orders
, ecom_avg_sale
, ecom_profit_per_order
, ecom_profit
, mem_visitors
, mem_cart_customers
, mem_cart_capture_rate
, mem_cart_profit_per_cust
, mem_cart_profit
, mem_cart_avg_sale
FROM fact_mus_store_analysis