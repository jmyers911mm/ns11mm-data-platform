/*
  stg_google_ads__campaigns
  Source: google_ads.raw_google_ads_campaignperformance (NS11MM_DW_DEV.RAW)

  The Google Ads pipeline extracts CampaignPerformance via GAQL search_stream.
  Fields match exactly what was selected in the pipeline GAQL query.
  Costs are in micros (divide by 1,000,000 to get USD).
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('google_ads', 'raw_google_ads_campaignperformance') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:date::date                               as report_date,
        _raw_data:campaign_id::varchar                     as campaign_id,
        _raw_data:campaign_name::varchar                   as campaign_name,
        _raw_data:status::varchar                          as campaign_status,
        _raw_data:impressions::integer                     as impressions,
        _raw_data:clicks::integer                          as clicks,
        _raw_data:cost_micros::integer                     as cost_micros,
        (_raw_data:cost_micros::float / 1000000)           as cost_usd,
        _raw_data:conversions::float                       as conversions,
        case
            when _raw_data:impressions::integer > 0
            then _raw_data:clicks::float / _raw_data:impressions::float
            else 0
        end                                                as click_through_rate,
        case
            when _raw_data:clicks::integer > 0
            then (_raw_data:cost_micros::float / 1000000) / _raw_data:clicks::float
            else null
        end                                                as cost_per_click_usd,
        case
            when _raw_data:conversions::float > 0
            then (_raw_data:cost_micros::float / 1000000) / _raw_data:conversions::float
            else null
        end                                                as cost_per_conversion_usd,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
