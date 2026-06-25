/*
  silver_sf_marketing_cloud
  Source: stg_salesforce_mc__tracking
  STATUS: Awaiting RAW data.
  Logic migrated from POC with production refs.
*/

{{
    config(
        materialized='incremental',
        unique_key='send_id',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        cluster_by=['event_date', 'campaign_id'],
        tags=['daily', 'critical']
    )
}}

select
    send_id,
    email_send_id,
    event_date::date                                        as event_date,
    subscriber_key,
    email_address,
    event_type,
    job_id                                                  as campaign_id,
    null::varchar                                           as campaign_name,
    null::varchar                                           as subject_line,
    null::varchar                                           as link_url,
    null::varchar                                           as device_type,
    null::varchar                                           as operating_system,
    null::varchar                                           as bounce_type,
    case when event_type = 'Bounce'       then true else false end as is_bounced,
    case when event_type = 'Unsubscribe'  then true else false end as is_unsubscribed,
    email_domain,
    hashdiff,
    _extracted_at
from {{ ref('stg_salesforce_mc__tracking') }}

{% if is_incremental() %}
where _extracted_at > (select max(_extracted_at) from {{ this }})
{% endif %}
