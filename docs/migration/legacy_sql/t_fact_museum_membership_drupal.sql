-- TRANSFORMATION: t_fact_museum_membership_drupal
-- DESC: 

-- WRITES: 911DW:.fact_museum_membership_drupal (TableOutput)


-- ===== STEP: Museum Membership - Drupal [TableInput] conn=Ecommerce =====
SELECT 
DATE_FORMAT(FROM_UNIXTIME(o.created), '%Y%m%d') as date_created, DATE_FORMAT(FROM_UNIXTIME(o.modified), '%Y%m%d') as date_modified, 
o.order_id,
SUM(op.qty) as quantity, SUM(op.price) as revenue, 
o.primary_email, o.billing_first_name, o.billing_last_name, o.billing_phone, o.billing_street1,o.billing_street2, o.billing_city, 
o.billing_postal_code, o.billing_zone
FROM uc_order_products as op 
INNER JOIN uc_orders as o ON o.order_id = op.order_id 
WHERE o.order_status = 'completed' AND op.model LIKE 'membership-%' 
GROUP BY date_modified,
o.order_id, 
o.primary_email,
o.billing_first_name,
o.billing_last_name, 
o.billing_phone, 
o.billing_street1,
o.billing_street2, 
o.billing_city, 
o.billing_postal_code,
o.billing_zone, 
date_created
ORDER BY o.modified