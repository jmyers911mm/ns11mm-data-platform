/*
  stg_meta_ads__campaigns
  Source: meta_ads.raw_meta_ads_campaigninsights (NS11MM_DW_DEV.RAW)

  The Meta pipeline extracts CampaignInsights via the Marketing API /insights endpoint.
  Fields match the `fields` parameter set in the pipeline extract function.
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('meta_ads', 'raw_meta_ads_campaigninsights') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:campaign_id::varchar                     as campaign_id,
        _raw_data:campaign_name::varchar                   as campaign_name,
        _raw_data:date_start::date                         as date_start,
        _raw_data:date_stop::date                          as date_stop,
        _raw_data:impressions::integer                     as impressions,
        _raw_data:clicks::integer                          as clicks,
        _raw_data:spend::number(10,2)                      as spend_usd,
        _raw_data:reach::integer                           as reach,
        _raw_data:cpm::number(10,4)                        as cpm,
        _raw_data:cpc::number(10,4)                        as cpc,
        _raw_data:ctr::number(10,6)                        as click_through_rate,
        _raw_data:frequency::number(10,4)                  as frequency,
        _raw_data:actions::variant                         as actions_raw,
        _raw_data:conversions::variant                     as conversions_raw,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
