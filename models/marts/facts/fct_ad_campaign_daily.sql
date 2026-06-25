/*
  fct_ad_campaign_daily
  Sources: silver_google_ads + silver_meta_ads
  STATUS: Awaiting RAW data. Logic migrated from POC.
  Campaign-level daily summary across all ad platforms.
*/

{{ config(materialized='table', cluster_by=['report_date', 'ad_platform']) }}

select
    report_date,
    'Google Ads'    as ad_platform,
    campaign_id,
    campaign_name,
    campaign_status,
    campaign_category,
    sum(impressions) as impressions,
    sum(clicks)      as clicks,
    sum(cost)        as spend,
    sum(conversions) as conversions,
    null::number     as reach,
    null::float      as frequency,
    case when sum(impressions) > 0 then sum(clicks)::float / sum(impressions) else 0 end as ctr,
    case when sum(clicks) > 0 then sum(cost) / sum(clicks) else null end as avg_cpc,
    case when sum(conversions) > 0 then sum(cost) / sum(conversions) else null end as cost_per_conversion,
    case when sum(cost) > 0 then sum(conversions) / sum(cost) else null end as roas,
    current_timestamp() as _loaded_at
from {{ ref('silver_google_ads') }}
group by report_date, campaign_id, campaign_name, campaign_status, campaign_category

union all

select
    ad_date         as report_date,
    'Meta Ads'      as ad_platform,
    campaign_id,
    campaign_name,
    null::varchar   as campaign_status,
    campaign_category,
    sum(impressions) as impressions,
    sum(clicks)      as clicks,
    sum(spend)       as spend,
    null::float      as conversions,
    sum(reach)       as reach,
    avg(frequency)   as frequency,
    case when sum(impressions) > 0 then sum(clicks)::float / sum(impressions) else 0 end as ctr,
    case when sum(clicks) > 0 then sum(spend) / sum(clicks) else null end as avg_cpc,
    null::number     as cost_per_conversion,
    null::float      as roas,
    current_timestamp() as _loaded_at
from {{ ref('silver_meta_ads') }}
group by ad_date, campaign_id, campaign_name, campaign_category
