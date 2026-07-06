/*
  silver_google_analytics
  Source: stg_ga4__sessions
  STATUS: Awaiting RAW data.
  Logic migrated from POC with production refs and GA4 field names.
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
    session_date,
    session_source                                          as source,
    session_medium                                          as medium,
    session_campaign_name                                   as campaign,
    case
        when session_medium = 'cpc'                 then 'Paid Search'
        when session_medium in ('paid', 'paidsocial') then 'Paid Social'
        when session_medium = 'organic'             then 'Organic Search'
        when session_medium in ('email', 'newsletter') then 'Email'
        when session_source = '(direct)'            then 'Direct'
        else 'Other'
    end                                                     as channel_grouping,
    landing_page                                            as page_path,
    case
        when landing_page like '%ticket%'           then 'Tickets'
        when landing_page like '%member%'           then 'Membership'
        when landing_page like '%gift%'
          or landing_page like '%shop%'             then 'Retail'
        when landing_page like '%exhib%'            then 'Exhibitions'
        when landing_page like '%donat%'            then 'Donations'
        else 'General'
    end                                                     as page_category,
    device_category,
    country,
    browser,
    sessions,
    engaged_sessions,
    active_users,
    new_users,
    total_users,
    page_views,
    avg_session_duration_seconds,
    engagement_rate,
    bounce_rate,
    conversions,
    hashdiff,
    _extracted_at
from {{ ref('stg_ga4__sessions') }}

{% if is_incremental() %}
where _extracted_at > (select max(_extracted_at) from {{ this }})
{% endif %}
