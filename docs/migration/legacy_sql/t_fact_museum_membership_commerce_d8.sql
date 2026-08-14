-- TRANSFORMATION: t_fact_museum_membership_commerce_d8
-- DESC: 

-- WRITES: 911DW:.fact_museum_membership_drupal (InsertUpdate)
-- WRITES: 911DW:.fact_museum_donations_drupal (InsertUpdate)


-- ===== STEP: Museum Membership - D7 [TableInput] conn=Ecommerce - D7 =====
SELECT commerce_order.order_id AS order_id,
commerce_order.order_number AS order_number, 
concat(substr(cast(FROM_UNIXTIME(commerce_order.created) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),9,2)) as date_created,
concat(substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),9,2)) as date_modified,
commerce_product.sku AS sku,
commerce_order.status AS order_status, 
commerce_order.mail AS order_mail,
commerce_line_item.quantity AS quantity,
(field_data_commerce_unit_price.commerce_unit_price_amount)/100 as unit_price,
(commerce_payment_transaction.amount)/100 as order_total,
field_data_commerce_customer_address.commerce_customer_address_first_name as billing_first_name,
field_data_commerce_customer_address.commerce_customer_address_last_name as billing_last_name,
field_data_commerce_customer_address.commerce_customer_address_thoroughfare as billing_street_1,
field_data_commerce_customer_address.commerce_customer_address_premise as billing_street_2,
field_data_commerce_customer_address.commerce_customer_address_locality as billing_city,
field_data_commerce_customer_address.commerce_customer_address_administrative_area as billing_state,
field_data_commerce_customer_address.commerce_customer_address_country as billing_country, 
field_data_commerce_customer_address.commerce_customer_address_postal_code as billing_zipcode

from
commerce_order commerce_order
LEFT JOIN field_data_commerce_line_items ON commerce_order.order_id = field_data_commerce_line_items.entity_id AND field_data_commerce_line_items.entity_type = 'commerce_order'
LEFT JOIN commerce_line_item  ON field_data_commerce_line_items.commerce_line_items_line_item_id = commerce_line_item.line_item_id
LEFT JOIN commerce_payment_transaction  ON commerce_order.order_id = commerce_payment_transaction.order_id
LEFT JOIN field_data_commerce_product ON commerce_line_item.line_item_id = field_data_commerce_product.entity_id AND field_data_commerce_product.entity_type = 'commerce_line_item'
LEFT JOIN field_data_commerce_unit_price ON commerce_line_item.line_item_id=field_data_commerce_unit_price.entity_id and field_data_commerce_product.entity_type ='commerce_line_item'
LEFT JOIN commerce_product ON field_data_commerce_product.commerce_product_product_id = commerce_product.product_id
LEFT JOIN field_data_commerce_customer_billing ON commerce_order.order_id = field_data_commerce_customer_billing.entity_id AND field_data_commerce_customer_billing.entity_type = 'commerce_order'
LEFT JOIN commerce_customer_profile ON field_data_commerce_customer_billing.commerce_customer_billing_profile_id = commerce_customer_profile.profile_id
LEFT JOIN field_data_commerce_customer_address ON commerce_customer_profile.profile_id= field_data_commerce_customer_address.entity_id and field_data_commerce_customer_address.entity_type = 'commerce_customer_profile'
WHERE  commerce_line_item.type IN  ('commerce_donate', 'product')
and commerce_order.status NOT IN  ('cart', 'checkout_checkout', 'checkout_shipping', 'checkout_review', 'checkout_payment', 'canceled','checkout_donate')
and commerce_product.sku like '%membership%'
and 
concat(substr(cast(FROM_UNIXTIME(commerce_order.created) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),9,2)) >= '20161110'
GROUP BY order_id, 
order_number, 
concat(substr(cast(FROM_UNIXTIME(commerce_order.created) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),9,2)),
concat(substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),9,2)),
sku,
order_status,
order_mail,
billing_first_name,
billing_last_name,
billing_street_1,
billing_street_2,
billing_city, 
billing_state,
billing_country,
billing_zipcode
ORDER BY
concat(substr(cast(FROM_UNIXTIME(commerce_order.created) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),9,2))

-- ===== STEP: Museum Web Donations - D7 [TableInput] conn=Ecommerce - D7 =====
SELECT commerce_order.order_id AS order_id,
commerce_order.order_number AS order_number, 
concat(substr(cast(FROM_UNIXTIME(commerce_order.created) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),9,2)) as date_created,
concat(substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),9,2)) as date_modified,
commerce_product.sku AS sku,
commerce_product.title as description,
commerce_order.status AS order_status, 
commerce_order.mail AS order_mail,
commerce_line_item.quantity AS quantity,
(field_data_commerce_unit_price.commerce_unit_price_amount)/100 as unit_price,
(commerce_payment_transaction.amount)/100 as order_total,
field_data_commerce_customer_address.commerce_customer_address_first_name as billing_first_name,
field_data_commerce_customer_address.commerce_customer_address_last_name as billing_last_name,
field_data_commerce_customer_address.commerce_customer_address_thoroughfare as billing_street_1,
field_data_commerce_customer_address.commerce_customer_address_premise as billing_street_2,
field_data_commerce_customer_address.commerce_customer_address_locality as billing_city,
field_data_commerce_customer_address.commerce_customer_address_administrative_area as billing_state,
field_data_commerce_customer_address.commerce_customer_address_country as billing_country, 
field_data_commerce_customer_address.commerce_customer_address_postal_code as billing_zipcode

from
commerce_order commerce_order
LEFT JOIN field_data_commerce_line_items ON commerce_order.order_id = field_data_commerce_line_items.entity_id AND field_data_commerce_line_items.entity_type = 'commerce_order'
LEFT JOIN commerce_line_item  ON field_data_commerce_line_items.commerce_line_items_line_item_id = commerce_line_item.line_item_id
LEFT JOIN commerce_payment_transaction  ON commerce_order.order_id = commerce_payment_transaction.order_id
LEFT JOIN field_data_commerce_product ON commerce_line_item.line_item_id = field_data_commerce_product.entity_id AND field_data_commerce_product.entity_type = 'commerce_line_item'
LEFT JOIN field_data_commerce_unit_price ON commerce_line_item.line_item_id=field_data_commerce_unit_price.entity_id and field_data_commerce_product.entity_type ='commerce_line_item'
LEFT JOIN commerce_product ON field_data_commerce_product.commerce_product_product_id = commerce_product.product_id
LEFT JOIN field_data_commerce_customer_billing ON commerce_order.order_id = field_data_commerce_customer_billing.entity_id AND field_data_commerce_customer_billing.entity_type = 'commerce_order'
LEFT JOIN commerce_customer_profile ON field_data_commerce_customer_billing.commerce_customer_billing_profile_id = commerce_customer_profile.profile_id
LEFT JOIN field_data_commerce_customer_address ON commerce_customer_profile.profile_id= field_data_commerce_customer_address.entity_id and field_data_commerce_customer_address.entity_type = 'commerce_customer_profile'
WHERE  commerce_line_item.type IN  ('commerce_donate', 'product')
and commerce_order.status NOT IN  ('cart', 'checkout_checkout', 'checkout_shipping', 'checkout_review', 'checkout_payment', 'canceled','checkout_donate')
and commerce_product.sku like '%donation%'
and 
concat(substr(cast(FROM_UNIXTIME(commerce_order.created) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),9,2)) >= '20161110'
and commerce_order.order_id <> 1228591
GROUP BY order_id, 
order_number, 
concat(substr(cast(FROM_UNIXTIME(commerce_order.created) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),9,2)),
concat(substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.changed) as char),9,2)),
sku,
description,
order_status,
order_mail,
billing_first_name,
billing_last_name,
billing_street_1,
billing_street_2,
billing_city, 
billing_state,
billing_country,
billing_zipcode
ORDER BY
concat(substr(cast(FROM_UNIXTIME(commerce_order.created) as char),1,4),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),6,2),substr(cast(FROM_UNIXTIME(commerce_order.created) as char),9,2))