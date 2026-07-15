{{ config(materialized='table') }}

-- Marts fact: daily scan (passes scanned + tickets sold by market segment)
-- ---------------------------------------------------------------------------
-- Domain: attendance / scanning
-- Grain:  one row per date_key x segment_key
--
-- The additive backbone of the Daily Scan Report
-- (report.daily_scan_report_new). One row per market segment per day with
-- passes-scanned and tickets-sold; percentages and market-mix shares are
-- computed at query grain in rpt_daily_scan.
--
-- Category from int_gateway__scan_lines is mapped to the reporting segment via
-- seed_scan_market_segment. Budget is left-joined from a stub (dsr forecasts)
-- to preserve the seam (ADR-005). ADR-004: additive only.

with lines as (
    select * from {{ ref('int_gateway__scan_lines') }}
),

segments as (
    select match_value, segment_key, segment_name
    from {{ ref('seed_scan_market_segment') }}
    where match_type = 'category'
),

classified as (
    select
        l.key_date,
        coalesce(s.segment_key, 'unmapped')      as segment_key,
        coalesce(s.segment_name, 'Unmapped')     as segment_name,
        l.scanned_qty,
        l.ticket_qty,
        l.is_valid_scan
    from lines l
    left join segments s on l.category = s.match_value
),

aggregated as (
    select
        key_date,
        segment_key,
        max(segment_name)                                        as segment_name,
        sum(case when is_valid_scan then try_to_decimal(scanned_qty::varchar, 18, 0) else 0 end) as passes_scanned,
        sum(try_to_decimal(ticket_qty::varchar, 18, 0))          as tickets_sold
    from classified
    group by 1, 2
),

budget as (
    -- Real DSR budget (fact_dsr_forecasts) is WIDE (a column per segment).
    -- Unpivot to segment_key to match fct grain. Segment keys align with
    -- seed_scan_market_segment.segment_key.
    select business_date as key_date, 'advance' as segment_key, advance as passes_budget from {{ ref('stg_budget__daily_scan') }}
    union all select business_date, 'walkup', walk_up from {{ ref('stg_budget__daily_scan') }}
    union all select business_date, 'self_organized_groups', self_organized_groups from {{ ref('stg_budget__daily_scan') }}
    union all select business_date, 'tour_travel', tour_travel from {{ ref('stg_budget__daily_scan') }}
    union all select business_date, 'citypass', citypass from {{ ref('stg_budget__daily_scan') }}
    union all select business_date, 'c3', c3_citypass from {{ ref('stg_budget__daily_scan') }}
    union all select business_date, 'newyork', new_york_pass from {{ ref('stg_budget__daily_scan') }}
    union all select business_date, 'explorer', explorer_pass from {{ ref('stg_budget__daily_scan') }}
    union all select business_date, 'sightseeing', sightseeing_pass from {{ ref('stg_budget__daily_scan') }}
    union all select business_date, 'gocity', gocity from {{ ref('stg_budget__daily_scan') }}
    union all select business_date, 'groups_schools', school_groups from {{ ref('stg_budget__daily_scan') }}
    union all select business_date, 'members', membership from {{ ref('stg_budget__daily_scan') }}
    union all select business_date, 'complimentary', comps from {{ ref('stg_budget__daily_scan') }}
),

final as (
    select
        dd.date_id                     as date_key,
        a.key_date                     as date_value,
        a.segment_key,
        a.segment_name,
        dd.is_commemoration_day,
        a.passes_scanned,
        a.tickets_sold,
        b.passes_budget
    from aggregated a
    inner join {{ ref('dim_date') }} dd on a.key_date = dd.date_id
    left join budget b on a.key_date = b.key_date and a.segment_key = b.segment_key
)

select * from final