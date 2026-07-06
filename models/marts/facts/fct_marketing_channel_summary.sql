/*
  fct_marketing_channel_summary
  Sources: int_google_ads + int_meta_ads + int_sf_marketing_cloud + fct_website_traffic
  STATUS: Awaiting RAW data. Logic migrated from POC.
  Cross-channel daily performance rollup.
*/

{{ config(enabled=false,materialized='table', cluster_by=['report_date']) }}

with paid_search as (
    select report_date, 'Paid Search' as channel, true as is_paid,
           sum(impressions) as impressions, sum(clicks) as clicks,
           sum(cost) as spend, sum(conversions) as conversions, null::number as conversion_value
    from {{ ref('int_google_ads') }} where campaign_status != 'REMOVED'
    group by report_date
),
paid_social as (
    select ad_date as report_date, 'Paid Social' as channel, true as is_paid,
           sum(impressions), sum(clicks), sum(spend), null::float, null::number
    from {{ ref('int_meta_ads') }}
    group by ad_date
),
email_ch as (
    select event_date as report_date, 'Email' as channel, false as is_paid,
           count(case when event_type = 'Sent' then 1 end) as impressions,
           count(case when event_type = 'Click' then 1 end) as clicks,
           0 as spend, 0 as conversions, null::number
    from {{ ref('int_sf_marketing_cloud') }}
    group by event_date
),
organic as (
    select report_date, 'Organic Search' as channel, false as is_paid,
           0 as impressions, sum(sessions) as clicks, 0, sum(conversions), null::number
    from {{ ref('fct_website_traffic') }} where channel_grouping = 'Organic Search'
    group by report_date
),
direct_ch as (
    select report_date, 'Direct' as channel, false as is_paid,
           0, sum(sessions), 0, sum(conversions), null::number
    from {{ ref('fct_website_traffic') }} where channel_grouping = 'Direct'
    group by report_date
),
all_channels as (
    select * from paid_search
    union all select * from paid_social
    union all select * from email_ch
    union all select * from organic
    union all select * from direct_ch
)

select
    ac.report_date,
    dd.fiscal_year,
    dd.month_name,
    dd.is_weekend,
    ac.channel,
    ac.is_paid,
    ac.impressions,
    ac.clicks,
    ac.spend,
    ac.conversions,
    case when ac.impressions > 0 then ac.clicks::float / ac.impressions else 0 end as ctr,
    case when ac.clicks > 0 then ac.spend / ac.clicks else null end as cpc,
    case when ac.conversions > 0 then ac.spend / ac.conversions else null end as cpa,
    current_timestamp() as _loaded_at
from all_channels ac
left join {{ ref('dim_date') }} dd on ac.report_date = dd.date_id
