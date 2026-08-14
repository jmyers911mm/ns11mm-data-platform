-- TRANSFORMATION: t_dim_city
-- DESC: City Dimension from Ecommerce

-- WRITES: 911DW:.dim_city (InsertUpdate)


-- ===== STEP: Ecommerce [TableInput] conn=Ecommerce =====
SELECT
billing_city
FROM uc_orders
group by billing_city