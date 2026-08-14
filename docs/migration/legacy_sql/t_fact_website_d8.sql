-- TRANSFORMATION: t_fact_website_d8
-- DESC: 

-- WRITES: 911DW:.fact_website_data_d8 (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=Ecommerce-D8 =====
SELECT 
commerce_order.order_id, 
commerce_order.mail,
concat(substr(cast(FROM_UNIXTIME(commerce_order.created) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),9,2)) as date_created,
concat(substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),9,2)) as date_modified,
commerce_order.type,
commerce_order__field_purchase_order_comment.field_purchase_order_comment_value,
commerce_product_variation_field_data.sku, 
commerce_order.state as status, 
commerce_order.type as order_type,
commerce_order_item.title,
commerce_order_item.quantity, 
commerce_order_item.unit_price__number
FROM
commerce_order_item commerce_order_item
LEFT JOIN commerce_order commerce_order ON commerce_order_item.order_id = commerce_order.order_id
LEFT JOIN commerce_product_variation_field_data ON commerce_order_item.purchased_entity = commerce_product_variation_field_data.variation_id
LEFT JOIN commerce_order__field_purchase_order_comment  ON commerce_order.order_id = commerce_order__field_purchase_order_comment.entity_id
WHERE commerce_order.type NOT IN ('membership_recurring', 'donation_monthly', 'recurring')
and commerce_product_variation_field_data.sku not like '%renewal%'
and commerce_order.state = 'completed'
and from_unixtime(commerce_order.created, '%Y-%m-%d')>= DATE_ADD(?, interval -5 day)
and commerce_order.mail NOT like '%unknown%'
ORDER BY commerce_order.order_id, commerce_order.created