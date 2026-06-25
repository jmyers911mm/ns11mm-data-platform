-- Verified Query: Retail by Category
-- Question: What are retail sales by product category?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_retail_revenue, total_retail_items_sold, retail_aov
  DIMENSIONS retail_items.item_category)
