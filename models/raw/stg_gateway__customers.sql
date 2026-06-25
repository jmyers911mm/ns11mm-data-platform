{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('gateway', 'raw_gateway_customers') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:CustomerId::varchar                   as customer_id,
        _raw_data:FirstName::varchar                    as first_name,
        _raw_data:LastName::varchar                     as last_name,
        _raw_data:Email::varchar                        as email,
        _raw_data:Phone::varchar                        as phone,
        _raw_data:IsMember::boolean                     as is_member,
        _raw_data:MembershipType::varchar               as membership_type,
        _raw_data:CreatedDate::timestamp                as created_at,
        _raw_data:LastModified::timestamp               as last_modified_at,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
