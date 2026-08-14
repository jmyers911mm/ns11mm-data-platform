-- TRANSFORMATION: t_fact_website_recurring_d8
-- DESC: 

-- WRITES: 911DW:.fact_website_recurring_data_d8 (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=Ecommerce-D8 =====
SELECT 
commerce_order.order_id as order_id, 
commerce_order.mail as mail,
concat(substr(cast(FROM_UNIXTIME(commerce_order.created) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),9,2)) as date_created,
concat(substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),9,2)) as date_modified,
concat(substr(cast(FROM_UNIXTIME(commerce_order.completed) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.completed) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.completed) as char),9,2)) as date_completed,
commerce_order.type as order_type,
commerce_order__field_purchase_order_comment.field_purchase_order_comment_value as purchase_order_comment,
commerce_product_variation_field_data.sku as sku, 
commerce_order.state as status, 
commerce_order_item.title as title,
commerce_order_item.quantity as quantity, 
commerce_order_item.unit_price__number as revenue
FROM
commerce_order_item commerce_order_item
LEFT JOIN commerce_order commerce_order ON commerce_order_item.order_id = commerce_order.order_id
LEFT JOIN commerce_product_variation_field_data ON commerce_order_item.purchased_entity = commerce_product_variation_field_data.variation_id
LEFT JOIN commerce_order__field_purchase_order_comment  ON commerce_order.order_id = commerce_order__field_purchase_order_comment.entity_id
WHERE commerce_order.type IN ('recurring')
and commerce_order.state = 'completed'
and from_unixtime(commerce_order.completed, '%Y-%m-%d')>= '20191030'
and commerce_order.mail NOT like '%unknown%'
ORDER BY commerce_order.completed, commerce_order.order_id