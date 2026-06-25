/*
  fct_campaign_performance
  Source: silver_sf_marketing_cloud
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{ config(materialized='table') }}

select
    campaign_id,
    campaign_name,
    min(event_date)                                         as first_send_date,
    max(event_date)                                         as last_event_date,
    count(case when event_type = 'Sent'        then 1 end) as total_sent,
    count(case when event_type = 'Open'        then 1 end) as total_opens,
    count(case when event_type = 'Click'       then 1 end) as total_clicks,
    count(case when event_type = 'Bounce'      then 1 end) as total_bounces,
    count(case when event_type = 'Unsubscribe' then 1 end) as total_unsubscribes,
    count(distinct subscriber_key)                          as unique_recipients,
    round(div0(
        count(case when event_type = 'Open' then 1 end)::float,
        nullif(count(case when event_type = 'Sent' then 1 end), 0)
    ) * 100, 2)                                             as open_rate_pct,
    round(div0(
        count(case when event_type = 'Click' then 1 end)::float,
        nullif(count(case when event_type = 'Open' then 1 end), 0)
    ) * 100, 2)                                             as click_to_open_rate_pct,
    round(div0(
        count(case when event_type = 'Bounce' then 1 end)::float,
        nullif(count(case when event_type = 'Sent' then 1 end), 0)
    ) * 100, 2)                                             as bounce_rate_pct,
    round(div0(
        count(case when event_type = 'Unsubscribe' then 1 end)::float,
        nullif(count(case when event_type = 'Sent' then 1 end), 0)
    ) * 100, 2)                                             as unsubscribe_rate_pct,
    current_timestamp()                                     as _loaded_at
from {{ ref('silver_sf_marketing_cloud') }}
group by campaign_id, campaign_name
