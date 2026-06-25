/*
  stg_ga4__sessions
  Source: ga4.raw_ga4_sessionreport (NS11MM_DW_DEV.RAW)

  The GA4 Data API returns report rows — each row is a combination of
  dimension values and metric values for a given date. This staging model
  exposes the session-level report we defined in the GA4 pipeline.

  NOTE: GA4 API field names are camelCase. When landed as JSON the keys
  will match exactly what was requested in the pipeline's RunReportRequest.
  Confirm field names by running:
    SELECT _raw_data FROM NS11MM_DW_DEV.RAW.RAW_GA4_SESSIONREPORT LIMIT 1;
*/

{{ config(materialized='view') }}

with source as (
    select
        _extracted_at,
        _raw_data
    from {{ source('ga4', 'raw_ga4_sessionreport') }}
),

renamed as (
    select
        _extracted_at,

        -- Dimensions
        _raw_data:date::varchar                             as session_date,
        _raw_data:sessionSource::varchar                   as session_source,
        _raw_data:sessionMedium::varchar                   as session_medium,
        _raw_data:sessionCampaignName::varchar             as session_campaign_name,
        _raw_data:country::varchar                         as country,
        _raw_data:deviceCategory::varchar                  as device_category,
        _raw_data:operatingSystem::varchar                 as operating_system,
        _raw_data:browser::varchar                         as browser,
        _raw_data:landingPage::varchar                     as landing_page,
        _raw_data:pageTitle::varchar                       as page_title,

        -- User metrics
        _raw_data:activeUsers::integer                     as active_users,
        _raw_data:newUsers::integer                        as new_users,
        _raw_data:totalUsers::integer                      as total_users,

        -- Session metrics
        _raw_data:sessions::integer                        as sessions,
        _raw_data:engagedSessions::integer                 as engaged_sessions,
        _raw_data:engagementRate::float                    as engagement_rate,
        _raw_data:bounceRate::float                        as bounce_rate,
        _raw_data:averageSessionDuration::float            as avg_session_duration_seconds,
        _raw_data:sessionsPerUser::float                   as sessions_per_user,

        -- Page metrics
        _raw_data:screenPageViews::integer                 as page_views,
        _raw_data:screenPageViewsPerSession::float         as page_views_per_session,

        -- Event / conversion metrics
        _raw_data:eventCount::integer                      as event_count,
        _raw_data:conversions::float                       as conversions,

        {{ generate_hashdiff(['_extracted_at::varchar', "coalesce(_raw_data:date::varchar,'')", "coalesce(_raw_data:sessionSource::varchar,'')", "coalesce(_raw_data:sessionMedium::varchar,'')"]) }} as hashdiff

    from source
)

select * from renamed
