-- Marts report: Tracker week-bucket dimension (rolling Mon-Sun buckets for the Daily Tracker matrix)
-- ---------------------------------------------------------------------------
-- Domain: DPR / cross-domain
-- Grain:  one row per date_key
--
-- Serving dimension for the Memorial & Museum Daily Tracker's lower matrix:
-- assigns every calendar date to one of six rolling buckets relative to the
-- tracker's as-of date (yesterday, America/New_York) —
--   'Prior Years'          dates in earlier calendar years
--   '1/1 - MM/DD'          current year up to the three broken-out weeks
--   three 'MM/DD - MM/DD'  the current Mon-Sun week and the two full weeks
--                          before it
--   'Future'               anything after the current week (filter out in
--                          the report)
-- bucket_sort is a date usable as the Power BI "sort by" column (sentinels:
-- 1900-01-01 for Prior Years, 9999-01-01 for Future).
--
-- The anchor is computed at QUERY time (view + current_timestamp), so the
-- buckets are always current under DirectQuery even if dim_date's nightly
-- rebuild is delayed; the Mon-Sun bounds themselves are static dim_date
-- columns (week_start_monday / week_end_sunday, added 7.12.1). This is
-- display grouping relative to the reporting date, not a metric — the
-- bucket definition lives here per ADR-004 instead of in a Power BI
-- calculated column.
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

with anchor as (
    -- Tracker as-of: yesterday, Eastern time (matches rpt_tracker_narrative_brief)
    select
        dateadd(day, -1, convert_timezone('America/New_York', current_timestamp())::date) as asof_date
),

anchor_week as (
    select
        asof_date,
        dateadd(day, -1 * mod(dayofweek(asof_date) + 6, 7), asof_date) as cur_week_start,
        dateadd(day, 6 - mod(dayofweek(asof_date) + 6, 7), asof_date)  as cur_week_end
    from anchor
),

d as (
    select date_key, week_start_monday, week_end_sunday
    from {{ ref('dim_date') }}
)

select
    d.date_key,
    case
        -- the current Mon-Sun week and the two full weeks before it
        when d.week_start_monday between dateadd(day, -14, aw.cur_week_start) and aw.cur_week_start
            then to_char(d.week_start_monday, 'mm/dd') || ' - ' || to_char(d.week_end_sunday, 'mm/dd')
        when d.date_key > aw.cur_week_end
            then 'Future'
        when year(d.date_key) < year(aw.asof_date)
            then 'Prior Years'
        else '1/1 - ' || to_char(dateadd(day, -15, aw.cur_week_start), 'mm/dd')
    end as week_bucket,
    case
        when d.week_start_monday between dateadd(day, -14, aw.cur_week_start) and aw.cur_week_start
            then d.week_start_monday
        when d.date_key > aw.cur_week_end
            then '9999-01-01'::date
        when year(d.date_key) < year(aw.asof_date)
            then '1900-01-01'::date
        else date_from_parts(year(aw.asof_date), 1, 1)
    end as bucket_sort
from d
cross join anchor_week aw
