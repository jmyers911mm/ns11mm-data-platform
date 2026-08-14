-- TRANSFORMATION: t_set_hold_date_ecommerce
-- DESC: Set the date that the next run will start

-- WRITES: 911DW:.run_date_ecommerce_hold (TableOutput)


-- ===== STEP: Ecommerce - max(created) [TableInput] conn=Ecommerce =====
SELECT
max(from_unixtime(created)) as created
FROM uc_orders