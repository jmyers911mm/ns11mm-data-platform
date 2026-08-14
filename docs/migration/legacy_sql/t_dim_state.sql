-- TRANSFORMATION: t_dim_state
-- DESC: State Dimension from Ecommerce

-- WRITES: 911DW:.dim_state (InsertUpdate)


-- ===== STEP: Ecommerce [TableInput] conn=Ecommerce =====
SELECT
zone_code
FROM uc_zones, uc_orders
where zone_id=billing_zone
group by zone_code