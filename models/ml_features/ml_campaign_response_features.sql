/*
  ml_campaign_response_features
  Sources: int_sf_marketing_cloud + dim_campaign + fct_website_traffic
  STATUS: Awaiting RAW data. Logic migrated from POC — updated refs.
*/

{{ config(enabled=false,materialized='table', tags=['daily', 'non-critical']) }}

with subscriber_engagement as (
    select
        subscriber_key, email_address,
        count(distinct campaign_id)                        as campaigns_received,
        count(distinct case when event_type = 'Open'  then campaign_id end) as campaigns_opened,
        count(distinct case when event_type = 'Click' then campaign_id end) as campaigns_clicked,
        div0(count(distinct case when event_type = 'Open'  then campaign_id end)::float,
             count(distinct case when event_type = 'Sent'  then campaign_id end)) as open_rate,
        div0(count(distinct case when event_type = 'Click' then campaign_id end)::float,
             count(distinct case when event_type = 'Open'  then campaign_id end)) as click_to_open_rate,
        max(case when event_type = 'Open' then event_date end) as last_open_date,
        datediff('day', max(case when event_type = 'Open' then event_date end), current_date()) as days_since_last_open
    from {{ ref('int_sf_marketing_cloud') }}
    group by subscriber_key, email_address
),

web_engagement as (
    select
        source, campaign,
        sum(sessions)                                      as email_driven_sessions,
        sum(conversions)                                   as email_driven_conversions,
        avg(avg_session_duration_seconds)                  as avg_email_session_duration
    from {{ ref('fct_website_traffic') }}
    where medium in ('email', 'newsletter')
    group by source, campaign
)

select
    se.subscriber_key, se.email_address,
    se.campaigns_received, se.campaigns_opened, se.campaigns_clicked,
    se.open_rate, se.click_to_open_rate,
    se.last_open_date, se.days_since_last_open,
    coalesce(we.email_driven_sessions, 0)                  as email_driven_sessions,
    coalesce(we.email_driven_conversions, 0)               as email_driven_conversions,
    case
        when se.open_rate >= 0.5 then 'Highly Engaged'
        when se.open_rate >= 0.2 then 'Moderately Engaged'
        when se.open_rate > 0    then 'Low Engagement'
        else 'Non-Responder'
    end                                                    as engagement_tier,
    current_timestamp()                                    as _feature_computed_at
from subscriber_engagement se
left join web_engagement we on se.email_address = we.source
