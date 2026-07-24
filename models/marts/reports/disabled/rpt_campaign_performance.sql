-- Rename fiscal_year to year for simplified calendar dimensions
-- Co-authored with CoCo
/*
  rpt_campaign_performance
  Sources: fct_campaign_performance + dim_campaign + dim_date
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{ config(enabled=false,materialized='table') }}

select
    cp.campaign_id,
    dc.campaign_name,
    dc.campaign_type,
    dc.campaign_channel,
    dc.audience_size_tier,
    dc.campaign_duration_days,
    cp.first_send_date,
    dd.year_number as year,
    dd.month_name,
    dd.is_weekend                                          as sent_on_weekend,
    cp.last_event_date,
    cp.total_sent,
    cp.total_opens,
    cp.total_clicks,
    cp.total_bounces,
    cp.total_unsubscribes,
    cp.unique_recipients,
    cp.open_rate_pct,
    cp.click_to_open_rate_pct,
    cp.bounce_rate_pct,
    cp.unsubscribe_rate_pct,
    datediff('day', cp.first_send_date, cp.last_event_date) as engagement_window_days
from {{ ref('fct_campaign_performance') }} cp
left join {{ ref('dim_campaign') }} dc on cp.campaign_id = dc.campaign_id
left join {{ ref('dim_date') }}     dd on cp.first_send_date = dd.date_id
