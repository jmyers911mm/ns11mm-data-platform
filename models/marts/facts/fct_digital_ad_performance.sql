/*
  fct_digital_ad_performance
  Sources: silver_google_ads + silver_meta_ads
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{ config(materialized='table', cluster_by=['report_date', 'ad_platform']) }}

select
    ad_date                                                 as report_date,
    'Google Ads'                                            as ad_platform,
    campaign_id,
    campaign_name,
    campaign_status,
    campaign_category,
    impressions,
    null::integer                                           as reach,
    null::float                                             as frequency,
    clicks,
    cost                                                    as spend,
    conversions,
    null::number(14,2)                                      as conversion_value,
    click_through_rate                                      as ctr,
    cost_per_click                                          as avg_cpc,
    cost_per_conversion,
    roas,
    current_timestamp()                                     as _loaded_at
from {{ ref('silver_google_ads') }}

union all

select
    ad_date                                                 as report_date,
    'Meta Ads'                                              as ad_platform,
    campaign_id,
    campaign_name,
    null::varchar                                           as campaign_status,
    campaign_category,
    impressions,
    reach,
    frequency,
    clicks,
    spend,
    null::float                                             as conversions,
    null::number(14,2)                                      as conversion_value,
    ctr,
    cost_per_click                                          as avg_cpc,
    null::number(14,2)                                      as cost_per_conversion,
    roas,
    current_timestamp()                                     as _loaded_at
from {{ ref('silver_meta_ads') }}
