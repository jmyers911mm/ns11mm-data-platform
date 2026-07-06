/*
  silver_google_ads
  Source: stg_google_ads__campaigns
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
    report_date,
    campaign_id,
    campaign_name,
    campaign_status,
    impressions,
    clicks,
    cost_micros,
    cost_usd                                                as cost,
    conversions,
    click_through_rate,
    cost_per_click_usd                                      as cost_per_click,
    cost_per_conversion_usd                                 as cost_per_conversion,
    case
        when cost_usd > 0 then conversions / nullif(cost_usd, 0)
        else null
    end                                                     as roas,
    case
        when campaign_name ilike '%ticket%' then 'Tickets'
        when campaign_name ilike '%member%' then 'Membership'
        when campaign_name ilike '%gift%'
          or campaign_name ilike '%shop%'  then 'Retail'
        else 'General'
    end                                                     as campaign_category,
    hashdiff,
    _extracted_at
from {{ ref('stg_google_ads__campaigns') }}

{% if is_incremental() %}
where _extracted_at > (select max(_extracted_at) from {{ this }})
{% endif %}
