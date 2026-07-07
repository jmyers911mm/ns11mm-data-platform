/*
  ml_marketing_attribution_features
  Source: int_google_analytics
  STATUS: Awaiting RAW data. Logic migrated from POC — no ref changes needed.
  First-touch and last-touch attribution for converting users.
*/

{{ config(enabled=false,materialized='table', tags=['daily', 'non-critical']) }}

with sessions as (
    select
        hashdiff as session_id, session_date, session_date as user_pseudo_id,
        source, medium, campaign, channel_grouping, page_category, device_category,
        conversions > 0 as is_conversion, sessions,
        row_number() over (partition by session_date order by session_date) as session_sequence,
        sum(case when conversions > 0 then 1 else 0 end) over (partition by session_date) as user_total_conversions
    from {{ ref('int_google_analytics') }}
),

converting_users as (
    select distinct user_pseudo_id from sessions where is_conversion
),

first_touch as (
    select user_pseudo_id, channel_grouping as first_touch_channel,
           source as first_touch_source, medium as first_touch_medium,
           campaign as first_touch_campaign, session_date as first_session_date
    from sessions
    where session_sequence = 1
      and user_pseudo_id in (select user_pseudo_id from converting_users)
),

last_touch as (
    select user_pseudo_id, channel_grouping as last_touch_channel,
           source as last_touch_source, medium as last_touch_medium,
           campaign as last_touch_campaign, session_date as conversion_date
    from sessions
    where is_conversion
    qualify row_number() over (partition by user_pseudo_id order by session_date desc) = 1
)

select
    f.user_pseudo_id, f.first_touch_channel, f.first_touch_source,
    f.first_touch_medium, f.first_touch_campaign, f.first_session_date,
    l.last_touch_channel, l.last_touch_source, l.last_touch_medium,
    l.last_touch_campaign, l.conversion_date,
    datediff('day', f.first_session_date, l.conversion_date) as days_to_convert,
    case when f.first_touch_channel = l.last_touch_channel then 'Single Touch' else 'Multi Touch' end as path_type,
    current_timestamp()                                    as _feature_computed_at
from first_touch f
left join last_touch l on f.user_pseudo_id = l.user_pseudo_id
