-- Verified Query: Top Selling Products
-- Question: What are the top selling products?
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS total_retail_revenue, total_retail_items_sold
  DIMENSIONS dim_product.product_name, dim_product.category, dim_product.price_tier)
