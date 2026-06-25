/*
  stg_salesforce_mc__tracking
  Source: salesforce_mc.raw_salesforce_mc_tracking_sent (NS11MM_DW_DEV.RAW)

  Salesforce Marketing Cloud tracking events (sends, opens, clicks, bounces,
  unsubscribes) are loaded into separate RAW tables by the pipeline.
  This staging model reads the sends table as the primary tracking grain.

  NOTE: The SFMC REST API tracking endpoints return items[] arrays.
  Field names match the SFMC tracking data extension schema.
  Confirm exact field names after first pipeline run.
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('salesforce_mc', 'raw_salesforce_mc_tracking_sent') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:ID::varchar                              as send_id,
        _raw_data:SendID::varchar                          as email_send_id,
        _raw_data:SubscriberKey::varchar                   as subscriber_key,
        _raw_data:EmailAddress::varchar                    as email_address,
        _raw_data:EventDate::timestamp_tz                  as event_date,
        _raw_data:EventType::varchar                       as event_type,
        _raw_data:JobID::varchar                           as job_id,
        _raw_data:ListID::varchar                          as list_id,
        _raw_data:BatchID::varchar                         as batch_id,
        _raw_data:TriggererSendDefinitionObjectID::varchar as triggered_send_id,
        _raw_data:Domain::varchar                          as email_domain,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
