/*
  stg_shopify__products
  Source: shopify.raw_shopify_products (NS11MM_DW_DEV.RAW)
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('shopify', 'raw_shopify_products') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:id::varchar                              as product_id,
        _raw_data:title::varchar                           as product_title,
        _raw_data:vendor::varchar                          as vendor,
        _raw_data:product_type::varchar                    as product_type,
        _raw_data:status::varchar                          as product_status,
        _raw_data:handle::varchar                          as product_handle,
        _raw_data:created_at::timestamp_tz                 as created_at,
        _raw_data:updated_at::timestamp_tz                 as updated_at,
        _raw_data:published_at::timestamp_tz               as published_at,
        _raw_data:tags::varchar                            as product_tags,
        _raw_data:variants::variant                        as variants_raw,
        _raw_data:options::variant                         as options_raw,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
