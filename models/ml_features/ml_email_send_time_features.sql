/*
  ml_email_send_time_features
  Source: silver_sf_marketing_cloud
  STATUS: Awaiting RAW data. Logic migrated from POC — updated refs.
  Identifies optimal email send time per subscriber.
*/

{{ config(enabled=false,materialized='table', tags=['daily', 'non-critical']) }}

with campaign_sends as (
    select
        subscriber_key, email_address, campaign_id,
        event_date::timestamp                              as send_timestamp,
        extract(hour from event_date::timestamp)           as send_hour,
        extract(dow from event_date::timestamp)            as send_dow
    from {{ ref('silver_sf_marketing_cloud') }}
    where event_type = 'Sent'
),

campaign_opens as (
    select
        subscriber_key, campaign_id,
        min(event_date::timestamp)                         as first_open_timestamp,
        extract(hour from min(event_date::timestamp))      as open_hour
    from {{ ref('silver_sf_marketing_cloud') }}
    where event_type = 'Open'
    group by subscriber_key, campaign_id
),

subscriber_history as (
    select
        subscriber_key,
        count(distinct case when event_type = 'Sent' then campaign_id end) as total_sends_received,
        count(distinct case when event_type = 'Open' then campaign_id end) as total_opens,
        div0(count(distinct case when event_type = 'Open' then campaign_id end)::float,
             count(distinct case when event_type = 'Sent' then campaign_id end)) as historical_open_rate
    from {{ ref('silver_sf_marketing_cloud') }}
    group by subscriber_key
)

select
    s.subscriber_key, s.email_address, s.campaign_id,
    s.send_timestamp, s.send_hour, s.send_dow,
    case when o.first_open_timestamp is not null then 1 else 0 end as was_opened,
    o.open_hour,
    datediff('minute', s.send_timestamp, o.first_open_timestamp) as minutes_to_open,
    sh.total_sends_received, sh.total_opens, sh.historical_open_rate,
    current_timestamp()                                    as _feature_computed_at
from campaign_sends s
left join campaign_opens    o  on s.subscriber_key = o.subscriber_key and s.campaign_id = o.campaign_id
left join subscriber_history sh on s.subscriber_key = sh.subscriber_key
