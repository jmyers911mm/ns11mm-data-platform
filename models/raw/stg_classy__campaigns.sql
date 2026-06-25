/*
  stg_classy__campaigns
  Source: classy.raw_classy_campaigns (NS11MM_DW_DEV.RAW)

  Classy REST API /organizations/{org_id}/campaigns endpoint.
  Field names match Classy API v2 response keys.
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('classy', 'raw_classy_campaigns') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:id::varchar                              as campaign_id,
        _raw_data:name::varchar                            as campaign_name,
        _raw_data:status::varchar                          as campaign_status,
        _raw_data:type::varchar                            as campaign_type,
        _raw_data:goal::number(12,2)                       as fundraising_goal,
        _raw_data:total_gross_amount::number(12,2)         as total_gross_raised,
        _raw_data:total_count_donors::integer              as total_donors,
        _raw_data:total_count_donations::integer           as total_donations,
        _raw_data:started_at::timestamp_tz                 as started_at,
        _raw_data:ended_at::timestamp_tz                   as ended_at,
        _raw_data:created_at::timestamp_tz                 as created_at,
        _raw_data:updated_at::timestamp_tz                 as updated_at,
        _raw_data:organization_id::varchar                 as organization_id,
        _raw_data:canonical_url::varchar                   as campaign_url,
        _raw_data:allow_duplicate_donations::boolean       as allow_duplicate_donations,
        _raw_data:allow_ecards::boolean                    as allow_ecards,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
