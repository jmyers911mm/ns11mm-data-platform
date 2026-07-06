/*
  fct_website_traffic
  Source: silver_google_analytics
  STATUS: Awaiting RAW data. Logic migrated from POC with GA4 field names.
*/

{{ config(enabled=false,materialized='table', cluster_by=['report_date']) }}

select
    session_date                                            as report_date,
    channel_grouping,
    source,
    medium,
    campaign,
    page_category,
    device_category,
    country,
    sum(sessions)                                           as sessions,
    sum(new_users)                                          as new_users,
    sum(active_users)                                       as active_users,
    sum(page_views)                                         as page_views,
    sum(engaged_sessions)                                   as engaged_sessions,
    sum(conversions)                                        as conversions,
    round(avg(avg_session_duration_seconds), 1)             as avg_session_duration_seconds,
    round(avg(engagement_rate), 4)                          as avg_engagement_rate,
    round(avg(bounce_rate), 4)                              as avg_bounce_rate,
    round(div0(sum(conversions)::float, nullif(sum(sessions), 0)) * 100, 2) as conversion_rate_pct,
    current_timestamp()                                     as _loaded_at
from {{ ref('silver_google_analytics') }}
group by session_date, channel_grouping, source, medium, campaign, page_category, device_category, country
