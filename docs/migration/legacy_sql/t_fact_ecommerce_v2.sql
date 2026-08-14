-- TRANSFORMATION: t_fact_ecommerce_v2
-- DESC: Ecommerce Sales Fact

-- WRITES: 911DW:.fact_ecommerce_2 (InsertUpdate)
-- LOOKUP: 911DW:.dim_city
-- LOOKUP: 911DW:.dim_country
-- LOOKUP: 911DW:.dim_customer_ecommerce
-- LOOKUP: 911DW:.dim_state
-- LOOKUP: 911DW:.dim_item_descr


-- ===== STEP: Ecommerce [TableInput] conn=Ecommerce =====
SELECT ORDERS.order_id,
ORDERS.order_status,
concat(substr(cast(FROM_UNIXTIME(ORDERS.created) as char),1,4),substr(cast(FROM_UNIXTIME(ORDERS.created) as char),6,2),substr(cast(FROM_UNIXTIME(ORDERS.created) as char),9,2)) as key_date,
ORDERS.uid,
ORDERS.billing_city,
ZONES.zone_code as state,
COUNTRY.country_iso_code_2,
PRODUCTS.title,
case when substring(PRODUCTS.model,1,8)='donation' or PRODUCTS.model= '300067' then 6 else 13 end as key_category,
sum(qty),
price
from ecommerce.uc_orders ORDERS, ecommerce.uc_zones ZONES,  ecommerce.uc_order_products PRODUCTS, ecommerce.uc_countries COUNTRY
where ORDERS.order_id = PRODUCTS.ORDER_ID AND
ORDERS.billing_zone=ZONES.zone_id and
ORDERS.billing_country=COUNTRY.country_id 
and
ORDERS.order_status in ("completed", "pending", "Shipped","payment_received", "processing") 
and
ORDERS.payment_method not in ("m911m_re")
and
concat(substr(cast(FROM_UNIXTIME(ORDERS.created) as char),1,4),substr(cast(FROM_UNIXTIME(ORDERS.created) as char),6,2),substr(cast(FROM_UNIXTIME(ORDERS.created) as char),9,2)) >='20150626'
group by order_id,
ORDERS.uid,
ORDERS.order_status,
FROM_UNIXTIME(ORDERS.created),
ORDERS.billing_city,
ZONES.zone_code,
PRODUCTS.title
order by FROM_UNIXTIME(ORDERS.created) desc