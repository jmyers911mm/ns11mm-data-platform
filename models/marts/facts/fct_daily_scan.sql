-- Marts fact: daily scan (passes scanned + tickets sold by market segment)
-- ---------------------------------------------------------------------------
-- Domain: attendance / scanning
-- Grain: one row per date_key x segment_key
--
-- The additive backbone of the Daily Scan Report
-- (report.daily_scan_report_new). One row per market segment per day with
-- passes-scanned and tickets-sold; percentages and market-mix shares are
-- computed at query grain in rpt_daily_scan.
--
-- Category from int_gateway__scan_lines is mapped to the reporting segment via
-- seed_scan_market_segment. Budget is left-joined from a stub (dsr forecasts)
-- to preserve the seam (ADR-005). ADR-004: additive only.
--
-- SCOPE NOTE (ADR-005 gate, 8.7.0) — owner Chris Wogas: passes_scanned is now
-- the NET legacy measure. int_ticket_scans applies the
-- t_fact_museum_passes_scanned rule -- Status = 0 AND Code = 0 adds, Status = 0
-- AND Code = 11 subtracts, every other usage code contributes nothing, and
-- Gateway facility 13 is excluded -- and hands down a signed net_scanned_qty.
-- The previous definition (status in 0,1; no code predicate; no reversal leg)
-- over-counted. passes_scanned can be negative for a single segment on a day
-- whose reversals exceed its entries; that is legacy behaviour and nets
-- correctly at the day total, so it is deliberately not floored at zero.
-- gross_passes_scanned is carried alongside for reconciliation.

{{ config(materialized='table') }}

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
        l.date_key,
        coalesce(s.segment_key, 'unmapped')      as segment_key,
        coalesce(s.segment_name, 'Unmapped')     as segment_name,
        l.scanned_qty,
        l.net_scanned_qty,
        l.ticket_qty,
        l.is_valid_scan,
        l.is_reversing_scan,
        l.is_counted_scan
    from lines l
    left join segments s on l.category = s.match_value
),

aggregated as (
    select
        date_key,
        segment_key,
        max(segment_name)                                        as segment_name,
        -- Decimal guards live upstream in int_gateway__scan_lines (DQ rule);
        -- tickets_sold is the scan-side proxy (see header).
        -- net_scanned_qty is already 0 for uncounted scans and negative for the
        -- code-11 leg, so this single SUM is the legacy UNION of both legs.
        sum(coalesce(net_scanned_qty, 0))                         as passes_scanned,
        sum(case when is_valid_scan then scanned_qty else 0 end)  as gross_passes_scanned,
        sum(case when is_reversing_scan then scanned_qty else 0 end) as reversed_passes_scanned,
        sum(ticket_qty)                                           as tickets_sold
    from classified
    group by 1, 2
),

budget as (
    -- Real DSR budget (fact_dsr_forecasts) is WIDE (a column per segment).
    -- Unpivot to segment_key to match fct grain. Segment keys align with
    -- seed_scan_market_segment.segment_key.
    -- INTENTIONALLY EXCLUDED: the staged `mobile` and `partners` budget
    -- columns have no segment_key in the seed and no row on the legacy Daily
    -- Scan Report (13 segments); add a seed row + a union branch here if the
    -- report ever grows them.
    select business_date as date_key, 'advance' as segment_key, advance as passes_budget from {{ ref('stg_budget__daily_scan') }}
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
        dd.date_key,
        a.date_key                     as date_value,
        a.segment_key,
        a.segment_name,
        dd.is_commemoration_day,
        a.passes_scanned,
        a.gross_passes_scanned,
        a.reversed_passes_scanned,
        a.tickets_sold,
        b.passes_budget
    from aggregated a
    inner join {{ ref('dim_date') }} dd on a.date_key = dd.date_key
    left join budget b on a.date_key = b.date_key and a.segment_key = b.segment_key
)

select * from final
