/*
  ml_ad_creative_features
  Sources: silver_google_ads + silver_meta_ads
  STATUS: Awaiting RAW data. Logic migrated from POC — updated refs.
*/

{{ config(enabled=false,materialized='table', tags=['daily', 'non-critical']) }}

with google_creative as (
    select
        report_date as ad_date, campaign_id, campaign_name, campaign_category,
        'Google Ads' as ad_platform, null::varchar as ad_name,
        impressions, clicks, cost as spend, conversions,
        click_through_rate as ctr, cost_per_click as cpc,
        cost_per_conversion as cpa, roas
    from {{ ref('silver_google_ads') }}
),

meta_creative as (
    select
        ad_date, campaign_id, campaign_name, campaign_category,
        'Meta Ads' as ad_platform, null::varchar as ad_name,
        impressions, clicks, spend,
        null::float as conversions, ctr, cost_per_click as cpc,
        null::number as cpa, roas
    from {{ ref('silver_meta_ads') }}
),

combined as (
    select * from google_creative
    union all
    select * from meta_creative
),

with_rolling as (
    select *,
           avg(ctr)  over (partition by ad_platform, campaign_category order by ad_date rows between 7 preceding and 1 preceding) as avg_ctr_7d,
           avg(roas) over (partition by ad_platform, campaign_category order by ad_date rows between 7 preceding and 1 preceding) as avg_roas_7d
    from combined
)

select *,
    case when ctr > coalesce(avg_ctr_7d, 0) * 1.2  then 'Above Average CTR'
         when ctr < coalesce(avg_ctr_7d, 0) * 0.8  then 'Below Average CTR'
         else 'Average CTR'
    end                                                    as ctr_performance_label,
    current_timestamp()                                    as _feature_computed_at
from with_rolling
