/*
  stg_salesforce_nps__campaigns
  Source: salesforce_nps.raw_salesforce_nps_campaign (NS11MM_DW_DEV.RAW)
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('salesforce_nps', 'raw_salesforce_nps_campaign') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:Id::varchar                              as campaign_id,
        _raw_data:Name::varchar                            as campaign_name,
        _raw_data:Status::varchar                          as campaign_status,
        _raw_data:Type::varchar                            as campaign_type,
        _raw_data:StartDate::date                          as start_date,
        _raw_data:EndDate::date                            as end_date,
        _raw_data:NumberOfLeads::integer                   as number_of_leads,
        _raw_data:NumberOfContacts::integer                as number_of_contacts,
        _raw_data:NumberOfOpportunities::integer           as number_of_opportunities,
        _raw_data:AmountWonOpportunities::number(14,2)     as amount_won_opportunities,
        _raw_data:CreatedDate::timestamp_tz                as created_at,
        _raw_data:LastModifiedDate::timestamp_tz           as last_modified_at,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
