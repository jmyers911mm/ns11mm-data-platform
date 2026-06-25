/*
  stg_shopify__customers
  Source: shopify.raw_shopify_customers (NS11MM_DW_DEV.RAW)
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('shopify', 'raw_shopify_customers') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:id::varchar                              as customer_id,
        _raw_data:email::varchar                           as email,
        _raw_data:first_name::varchar                      as first_name,
        _raw_data:last_name::varchar                       as last_name,
        _raw_data:phone::varchar                           as phone,
        _raw_data:created_at::timestamp_tz                 as created_at,
        _raw_data:updated_at::timestamp_tz                 as updated_at,
        _raw_data:orders_count::integer                    as orders_count,
        _raw_data:total_spent::number(10,2)                as total_spent,
        _raw_data:state::varchar                           as account_state,
        _raw_data:verified_email::boolean                  as verified_email,
        _raw_data:accepts_marketing::boolean               as accepts_marketing,
        _raw_data:accepts_marketing_updated_at::timestamp_tz as accepts_marketing_updated_at,
        _raw_data:marketing_opt_in_level::varchar          as marketing_opt_in_level,
        _raw_data:tax_exempt::boolean                      as is_tax_exempt,
        _raw_data:tags::varchar                            as customer_tags,
        _raw_data:note::varchar                            as customer_note,
        _raw_data:default_address:city::varchar            as city,
        _raw_data:default_address:province::varchar        as province,
        _raw_data:default_address:country::varchar         as country,
        _raw_data:default_address:zip::varchar             as zip,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
