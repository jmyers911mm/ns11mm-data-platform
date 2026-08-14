-- TRANSFORMATION: t_dim_item_desc_from_ecommerce
-- DESC: Retail Store Item Description

-- WRITES: 911DW:.dim_item_descr (InsertUpdate)


-- ===== STEP: Ecommerce [TableInput] conn=Ecommerce =====
SELECT
op.title,
op.model,
p.cost,
p.sell_price,
CONCAT('$',FORMAT(p.cost,2)) AS cost_str,
CONCAT('$',FORMAT(p.sell_price,2)) AS price_str
FROM  uc_order_products op INNER JOIN uc_products p  
ON op.nid = p.nid
GROUP BY op.title;