/*
  ml_ad_budget_optimization_features
  Source: fct_digital_ad_performance
  STATUS: Awaiting RAW data. Logic migrated from POC — no ref changes needed.
*/

{{ config(enabled=false,materialized='table', tags=['daily', 'non-critical']) }}

with platform_daily as (
    select report_date, ad_platform, campaign_category,
           sum(impressions) as impressions, sum(clicks) as clicks,
           sum(spend) as spend, sum(conversions) as conversions,
           case when sum(impressions) > 0 then sum(clicks)::float / sum(impressions) else 0 end as ctr,
           case when sum(clicks) > 0     then sum(spend) / sum(clicks)               else null end as cpc,
           case when sum(conversions) > 0 then sum(spend) / sum(conversions)          else null end as cpa,
           case when sum(spend) > 0      then sum(conversions) / sum(spend)           else null end as roas
    from {{ ref('fct_digital_ad_performance') }}
    group by report_date, ad_platform, campaign_category
),

platform_rolling as (
    select *,
           avg(spend)       over (partition by ad_platform, campaign_category order by report_date rows between 7 preceding and 1 preceding) as avg_spend_7d,
           avg(roas)        over (partition by ad_platform, campaign_category order by report_date rows between 7 preceding and 1 preceding) as avg_roas_7d,
           avg(cpa)         over (partition by ad_platform, campaign_category order by report_date rows between 7 preceding and 1 preceding) as avg_cpa_7d,
           avg(conversions) over (partition by ad_platform, campaign_category order by report_date rows between 7 preceding and 1 preceding) as avg_conversions_7d,
           sum(spend)       over (partition by ad_platform, campaign_category order by report_date rows between 30 preceding and 1 preceding) as cumulative_spend_30d,
           lag(roas, 1)     over (partition by ad_platform, campaign_category order by report_date) as prior_day_roas
    from platform_daily
)

select *,
    case when avg_roas_7d > 2 then 'Increase Budget'
         when avg_roas_7d < 1 then 'Reduce Budget'
         else 'Maintain'
    end                                                    as budget_recommendation,
    current_timestamp()                                    as _feature_computed_at
from platform_rolling
