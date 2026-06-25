/*
  stg_shopify__orders
  Source: shopify.raw_shopify_orders (NS11MM_DW_DEV.RAW)

  Shopify REST API order object fields. The pipeline extracts orders
  with status=any, paginated via Link header cursor.

  NOTE: Shopify REST API uses snake_case field names in JSON responses.
  Confirm by running:
    SELECT _raw_data FROM NS11MM_DW_DEV.RAW.RAW_SHOPIFY_ORDERS LIMIT 1;
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('shopify', 'raw_shopify_orders') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:id::varchar                              as order_id,
        _raw_data:order_number::integer                    as order_number,
        _raw_data:name::varchar                            as order_name,
        _raw_data:email::varchar                           as customer_email,
        _raw_data:phone::varchar                           as customer_phone,
        _raw_data:created_at::timestamp_tz                 as created_at,
        _raw_data:updated_at::timestamp_tz                 as updated_at,
        _raw_data:processed_at::timestamp_tz               as processed_at,
        _raw_data:cancelled_at::timestamp_tz               as cancelled_at,
        _raw_data:cancel_reason::varchar                   as cancel_reason,
        _raw_data:financial_status::varchar                as financial_status,
        _raw_data:fulfillment_status::varchar              as fulfillment_status,
        _raw_data:currency::varchar                        as currency,
        _raw_data:total_price::number(10,2)                as total_price,
        _raw_data:subtotal_price::number(10,2)             as subtotal_price,
        _raw_data:total_discounts::number(10,2)            as total_discounts,
        _raw_data:total_tax::number(10,2)                  as total_tax,
        _raw_data:total_shipping_price_set:shop_money:amount::number(10,2) as shipping_price,
        _raw_data:total_price_usd::number(10,2)            as total_price_usd,
        _raw_data:taxes_included::boolean                  as taxes_included,
        _raw_data:customer:id::varchar                     as shopify_customer_id,
        _raw_data:customer:first_name::varchar             as customer_first_name,
        _raw_data:customer:last_name::varchar              as customer_last_name,
        _raw_data:customer:orders_count::integer           as customer_orders_count,
        _raw_data:customer:total_spent::number(10,2)       as customer_total_spent,
        _raw_data:gateway::varchar                         as payment_gateway,
        _raw_data:payment_gateway_names::variant           as payment_gateway_names,
        _raw_data:source_name::varchar                     as order_source,
        _raw_data:referring_site::varchar                  as referring_site,
        _raw_data:landing_site::varchar                    as landing_site,
        _raw_data:billing_address:city::varchar            as billing_city,
        _raw_data:billing_address:province::varchar        as billing_province,
        _raw_data:billing_address:country::varchar         as billing_country,
        _raw_data:billing_address:zip::varchar             as billing_zip,
        _raw_data:shipping_address:city::varchar           as shipping_city,
        _raw_data:shipping_address:province::varchar       as shipping_province,
        _raw_data:shipping_address:country::varchar        as shipping_country,
        _raw_data:line_items::variant                      as line_items_raw,
        _raw_data:discount_codes::variant                  as discount_codes_raw,
        _raw_data:tags::varchar                            as order_tags,
        _raw_data:note::varchar                            as order_note,
        _raw_data:test::boolean                            as is_test_order,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff

    from source
)

select * from renamed
