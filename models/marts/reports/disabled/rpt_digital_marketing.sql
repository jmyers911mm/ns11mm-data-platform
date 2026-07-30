-- Rename fiscal_year to year for simplified calendar dimensions
/*
  rpt_digital_marketing
  Sources: fct_digital_ad_performance + fct_website_traffic + dim_date
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{ config(enabled=false,materialized='table') }}

select
    a.report_date,
    dd.day_of_week_name         as day_name,
    dd.is_weekend,
    dd.year_number as year,
    a.ad_platform,
    a.campaign_id,
    a.campaign_name,
    a.campaign_category,
    a.impressions,
    a.reach,
    a.clicks,
    a.spend,
    a.conversions,
    a.ctr,
    a.avg_cpc,
    a.roas,
    w.sessions,
    w.new_users,
    w.page_views,
    w.conversion_rate_pct,
    w.avg_session_duration_seconds,
    current_timestamp()         as _loaded_at
from {{ ref('fct_digital_ad_performance') }} a
left join {{ ref('fct_website_traffic') }} w
    on a.report_date = w.report_date
    and w.channel_grouping in ('Paid Search', 'Paid Social')
left join {{ ref('dim_date') }} dd on a.report_date = dd.date_id
