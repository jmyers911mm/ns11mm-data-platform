-- Marts report: Tracker analyst-notes card (pre-rendered fixed-width text block for the Power BI card)
-- ---------------------------------------------------------------------------
-- Domain: DPR / cross-domain / AI narrative
-- Grain:  one row (latest report_date)
--
-- Deterministic ASCII "Analyst Notes" card for the Memorial & Museum Daily
-- Tracker, rendered entirely in SQL from rpt_tracker_narrative_brief so
-- Power BI binds a plain view (works under DirectQuery — no
-- Value.NativeQuery, no DAX text assembly). YTD earned revenue vs
-- projection, the YTD scorecard, 7-day direction flags, and deterministic
-- watch items (falling 7-day trends + YTD lines off projection beyond
-- +/-5%). Bind the analyst_brief column to a card/table visual with a
-- monospace font and word wrap on.
-- NOTE: this is the deterministic sibling of the Cortex note in
-- TRACKER_PBI_NARRATIVE — it works before/without the T_TRACKER_NARRATIVE
-- task. The projection side inherits the tracker's open sign-off gates
-- (earned-revenue definition, projection basis).
--
-- ADR-004: presentation formatting lives here, not in Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

with n as (
    select report_date, brief_json
    from {{ ref('rpt_tracker_narrative_brief') }}
),

watch_src as (
    select n.report_date,
           initcap(replace(f.key::string, '_', ' ')) || ' trending down over the last 7 days' as item
    from n, lateral flatten(input => n.brief_json:direction_7d) f
    where f.value::string = 'falling'

    union all

    select n.report_date,
           'YTD earned revenue '
           || case when n.brief_json:ytd_earned_revenue:var_pct::float < 0
                   then 'behind' else 'ahead of' end
           || ' projection by '
           || trim(to_char(abs(round(n.brief_json:ytd_earned_revenue:var_pct::float * 100, 1)), '990.0')) || '%'
    from n
    where abs(n.brief_json:ytd_earned_revenue:var_pct::float) >= 0.05

    union all

    select n.report_date,
           'YTD museum attendance '
           || case when n.brief_json:ytd_museum_attendance:var_pct::float < 0
                   then 'behind' else 'ahead of' end
           || ' projection by '
           || trim(to_char(abs(round(n.brief_json:ytd_museum_attendance:var_pct::float * 100, 1)), '990.0')) || '%'
    from n
    where abs(n.brief_json:ytd_museum_attendance:var_pct::float) >= 0.05
),

watch as (
    select report_date,
           listagg('   • ' || item, '\n') within group (order by item) as block
    from watch_src
    group by report_date
)

select
    n.report_date,
       '════════════════════════════════════════════════════════════' || '\n'
    || '  MEMORIAL & MUSEUM DAILY TRACKER · ANALYST NOTES'             || '\n'
    || '  ' || dayname(n.report_date) || ', '
           || to_char(n.report_date, 'MON DD, YYYY') || ' · calendar YTD' || '\n'
    || '════════════════════════════════════════════════════════════' || '\n\n'
    || '  YTD earned revenue '
       || case when n.brief_json:ytd_earned_revenue:var_pct::float < 0
               then 'behind' else 'ahead of' end
       || ' projection by '
       || trim(to_char(abs(round(n.brief_json:ytd_earned_revenue:var_pct::float * 100, 1)), '990.0')) || '%' || '\n\n'
    || '  BOTTOM LINE (YTD)'                                            || '\n'
    || '  ------------------------------------------------------------'|| '\n'
    || '  Earned Revenue            $'
       || trim(to_char(n.brief_json:ytd_earned_revenue:actual::number(38,2), '999,999,990.00'))      || '\n'
    || '  Projection                $'
       || trim(to_char(n.brief_json:ytd_earned_revenue:projection::number(38,2), '999,999,990.00'))  || '\n'
    || '  Variance                  '
       || case when n.brief_json:ytd_earned_revenue:var_amount::number(38,2) < 0 then '-$' else '$' end
       || trim(to_char(abs(n.brief_json:ytd_earned_revenue:var_amount::number(38,2)), '999,999,990'))
       || '  (' || trim(to_char(round(n.brief_json:ytd_earned_revenue:var_pct::float * 100, 1), 'S990.0')) || '%)' || '\n\n'
    || '  YTD SCORECARD (actual vs projection)'                         || '\n'
    || '  ------------------------------------------------------------'|| '\n'
    || '   • Memorial attendance: '
       || trim(to_char(n.brief_json:ytd_memorial_attendance:actual::number(38,0), '999,999,990'))
       || ' vs ' || trim(to_char(n.brief_json:ytd_memorial_attendance:projection::number(38,0), '999,999,990'))
       || ' (' || trim(to_char(round(n.brief_json:ytd_memorial_attendance:var_pct::float * 100, 1), 'S990.0')) || '%)' || '\n'
    || '   • Museum attendance:   '
       || trim(to_char(n.brief_json:ytd_museum_attendance:actual::number(38,0), '999,999,990'))
       || ' vs ' || trim(to_char(n.brief_json:ytd_museum_attendance:projection::number(38,0), '999,999,990'))
       || ' (' || trim(to_char(round(n.brief_json:ytd_museum_attendance:var_pct::float * 100, 1), 'S990.0')) || '%)' || '\n'
    || '   • Tickets sold:        '
       || trim(to_char(n.brief_json:ytd_tickets_sold:actual::number(38,0), '999,999,990'))
       || ' vs ' || trim(to_char(n.brief_json:ytd_tickets_sold:projection::number(38,0), '999,999,990'))
       || ' (' || trim(to_char(round(n.brief_json:ytd_tickets_sold:var_pct::float * 100, 1), 'S990.0')) || '%)' || '\n\n'
    || '  7-DAY DIRECTION'                                              || '\n'
    || '  ------------------------------------------------------------'|| '\n'
    || '   • Earned revenue: '      || n.brief_json:direction_7d:earned_revenue::string      || '\n'
    || '   • Memorial attendance: ' || n.brief_json:direction_7d:memorial_attendance::string || '\n'
    || '   • Museum attendance: '   || n.brief_json:direction_7d:museum_attendance::string   || '\n\n'
    || '  WATCH ITEMS'                                                  || '\n'
    || '  ------------------------------------------------------------'|| '\n'
    || coalesce(wt.block, '   • none')                                  || '\n'
    || '  ------------------------------------------------------------'|| '\n'
    || '  Note: projection excludes donations and virtual-tour revenue' || '\n'
    || '  (not budgeted).'                                              || '\n'
    || '════════════════════════════════════════════════════════════'
        as analyst_brief
from n
left join watch wt on n.report_date = wt.report_date
