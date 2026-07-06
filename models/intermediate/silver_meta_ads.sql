/*
  silver_meta_ads
  Source: stg_meta_ads__campaigns
  STATUS: Awaiting RAW data.
  Logic migrated from POC with production refs.
*/

{{
    config(
        enabled=false,
        materialized='incremental',
        unique_key='hashdiff',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['daily', 'critical']
    )
}}

select
    campaign_id,
    campaign_name,
    date_start                                              as ad_date,
    impressions,
    reach,
    clicks,
    spend_usd                                               as spend,
    cpm,
    cpc                                                     as cost_per_click,
    click_through_rate                                      as ctr,
    frequency,
    case when clicks > 0 then spend_usd / clicks else null end      as cost_per_click_calc,
    case when spend_usd > 0 then clicks::float / nullif(spend_usd, 0) else null end as roas,
    case
        when campaign_name ilike '%member%'     then 'Membership'
        when campaign_name ilike '%promo%'
          or campaign_name ilike '%holiday%'   then 'Promotions'
        when campaign_name ilike '%awareness%'  then 'Awareness'
        else 'General'
    end                                                     as campaign_category,
    hashdiff,
    _extracted_at
from {{ ref('stg_meta_ads__campaigns') }}

{% if is_incremental() %}
where _extracted_at > (select max(_extracted_at) from {{ this }})
{% endif %}
