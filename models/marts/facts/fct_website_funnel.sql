/*
  fct_website_funnel
  Source: silver_google_analytics
  STATUS: Awaiting RAW data. Logic migrated from POC with GA4 field names.
*/

{{ config(enabled=false,materialized='table') }}

with session_pages as (
    select session_date, session_date as user_pseudo_id,
           channel_grouping, device_category, page_category,
           conversions > 0 as is_conversion, avg_session_duration_seconds
    from {{ ref('silver_google_analytics') }}
),
funnel_stages as (
    select
        session_date, channel_grouping, device_category,
        count(distinct user_pseudo_id) as total_visitors,
        count(distinct case when page_category = 'General'      then user_pseudo_id end) as stage_landing,
        count(distinct case when page_category = 'Tickets'      then user_pseudo_id end) as stage_tickets_viewed,
        count(distinct case when page_category = 'Membership'   then user_pseudo_id end) as stage_membership_viewed,
        count(distinct case when page_category = 'Retail'       then user_pseudo_id end) as stage_retail_viewed,
        count(distinct case when page_category = 'Exhibitions'  then user_pseudo_id end) as stage_exhibitions_viewed,
        count(distinct case when page_category = 'Donations'    then user_pseudo_id end) as stage_donations_viewed,
        count(distinct case when is_conversion  then user_pseudo_id end) as stage_converted,
        avg(avg_session_duration_seconds) as avg_session_duration
    from session_pages
    group by session_date, channel_grouping, device_category
)

select
    session_date as report_date,
    channel_grouping, device_category,
    total_visitors, stage_landing, stage_tickets_viewed,
    stage_membership_viewed, stage_retail_viewed, stage_exhibitions_viewed,
    stage_donations_viewed, stage_converted,
    case when total_visitors > 0 then round(stage_tickets_viewed::float / total_visitors * 100, 2) else 0 end as tickets_view_rate_pct,
    case when stage_tickets_viewed > 0 then round(stage_converted::float / stage_tickets_viewed * 100, 2) else 0 end as tickets_to_conversion_rate_pct,
    case when total_visitors > 0 then round(stage_converted::float / total_visitors * 100, 2) else 0 end as overall_conversion_rate_pct,
    avg_session_duration,
    current_timestamp() as _loaded_at
from funnel_stages
