-- TRANSFORMATION: t_dim_customer_ecommerce
-- DESC: 

-- WRITES: 911DW:.dim_customer_ecommerce (DimensionLookup)


-- ===== STEP: Build Customer Dim [TableInput] conn=Ecommerce =====
SELECT
distinct
uid
, ORDERS.billing_first_name
, ORDERS.billing_last_name
, ORDERS.primary_email
, ORDERS.billing_company
, ORDERS.billing_street1
, ORDERS.billing_street2
, ORDERS.billing_city
, ZONES.zone_code as state
, ORDERS.billing_postal_code
, COUNTRY.country_iso_code_2
, ORDERS.order_id
FROM uc_orders ORDERS, uc_zones ZONES, ecommerce.uc_countries COUNTRY
where 
ORDERS.billing_zone=ZONES.zone_id and
ORDERS.billing_country=COUNTRY.country_id
and 
concat(substr(cast(FROM_UNIXTIME(ORDERS.created) as char),1,4),substr(cast(FROM_UNIXTIME(ORDERS.created) as char),6,2),substr(cast(FROM_UNIXTIME(ORDERS.created) as char),9,2))>='20120713'