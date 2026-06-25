/*
  stg_gateway__ticket_types
  Source: gateway.raw_gateway_tickettypes (NS11MM_DW_DEV.RAW)

  Gateway Ticketing Galaxy ticket types reference table.
  TODO: Confirm exact column names with Kenny.
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('gateway', 'raw_gateway_tickettypes') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:TicketTypeId::varchar                    as ticket_type_id,
        _raw_data:TicketTypeName::varchar                  as ticket_type_name,
        _raw_data:TicketTypeCode::varchar                  as ticket_type_code,
        _raw_data:Category::varchar                        as category,
        _raw_data:DefaultPrice::number(10,2)               as default_price,
        _raw_data:IsActive::boolean                        as is_active,
        _raw_data:IsMemberType::boolean                    as is_member_type,
        _raw_data:IsTimedEntry::boolean                    as is_timed_entry,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
