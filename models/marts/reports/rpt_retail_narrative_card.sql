-- Marts report: Retail analyst-notes card (pre-rendered fixed-width text block for the Power BI card)
-- ---------------------------------------------------------------------------
-- Domain: retail / AI narrative
-- Grain:  one row (latest report_date)
--
-- Deterministic ASCII "Analyst Notes" card for the Retail Performance Report,
-- rendered entirely in SQL from rpt_retail_narrative_brief so Power BI binds
-- a plain view — works under DirectQuery, with no Value.NativeQuery and no
-- DAX text assembly. Twin of rpt_tracker_narrative_card.
-- Contents: headline GMS sales vs budget, bottom line, per-area splits,
-- MTD/YTD vs budget, top budget drivers, and deterministic watch items
-- (falling 7-day trends + budget movers beyond +/-10%).
-- Bind analyst_brief to a card/table visual with a monospace font and word
-- wrap on.
--
-- NOTE: this is the deterministic sibling of the Cortex prose note in
-- RETAIL_PBI_NARRATIVE — it works before/without T_RETAIL_NARRATIVE.
--
-- ADR-004: presentation formatting lives here, not in Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

with n as (
    select report_date, brief_json
    from {{ ref('rpt_retail_narrative_brief') }}
    qualify report_date = max(report_date) over ()
),

watch_src as (
    select
        n.report_date,
        case f.key::string
            when 'gms_sales' then 'GMS sales'
            when 'gm_profit' then 'GM profit'
            else initcap(replace(f.key::string, '_', ' '))
        end || ' trending down over the last 7 days' as item
    from n, lateral flatten(input => n.brief_json:direction_7d) f
    where f.value::string = 'falling'

    union all

    select
        n.report_date,
        f.value:line::string
        || case when f.value:var_pct::float < 0
                then ' behind budget by ' else ' ahead of budget by ' end
        || trim(to_char(abs(round(f.value:var_pct::float * 100, 1)), '990.0')) || '%'
    from n, lateral flatten(input => n.brief_json:top_budget_movers) f
    where abs(f.value:var_pct::float) >= 0.10
),

watch as (
    select report_date,
           listagg('   • ' || item, '\n') within group (order by item) as block
    from watch_src
    group by report_date
),

movers as (
    select
        n.report_date,
        listagg(
            '   • ' || f.value:line::string || ' — '
            || case when f.value:var_amount::number(38,2) < 0 then '-$' else '$' end
            || trim(to_char(abs(f.value:var_amount::number(38,2)), '999,999,990'))
            || ' (' || trim(to_char(round(f.value:var_pct::float * 100, 1), 'S990.0')) || '% vs budget)',
            '\n') within group (order by f.index) as block
    from n, lateral flatten(input => n.brief_json:top_budget_movers) f
    group by n.report_date
),

areas as (
    select
        n.report_date,
        listagg(
            '   • ' || rpad(f.value:label::string, 26)
            || '$' || trim(to_char(f.value:actual::number(38,2), '999,999,990.00'))
            || coalesce('  (' || trim(to_char(round(f.value:wow_pct::float * 100, 1), 'S990.0')) || '% WoW)', ''),
            '\n') within group (order by f.value:actual::number(38,2) desc) as block
    from n, lateral flatten(input => n.brief_json:metrics) f
    where f.key::string in (
        'museum_store_sales', 'memorial_carts_sales', 'museum_cafe_sales', 'ecommerce_gross_profit'
    )
    group by n.report_date
)

select
    n.report_date,
       '════════════════════════════════════════════════════════════' || '\n'
    || '  RETAIL PERFORMANCE REPORT · ANALYST NOTES'                   || '\n'
    || '  ' || dayname(n.report_date) || ', '
           || to_char(n.report_date, 'MON DD, YYYY')                    || '\n'
    || '════════════════════════════════════════════════════════════' || '\n\n'
    || '  Total GMS sales '
       || case when n.brief_json:metrics:total_gms_sales:var_pct::float < 0
               then 'behind' else 'ahead of' end
       || ' budget by '
       || trim(to_char(abs(round(n.brief_json:metrics:total_gms_sales:var_pct::float * 100, 1)), '990.0')) || '%'
       || case when n.brief_json:is_commemoration_day::boolean
                 or n.brief_json:in_commemoration_window::boolean
               then ' (commemoration period — elevated figures expected)' else '' end || '\n\n'
    || '  BOTTOM LINE'                                                  || '\n'
    || '  ------------------------------------------------------------'|| '\n'
    || '  GMS Sales                 $'
       || trim(to_char(n.brief_json:metrics:total_gms_sales:actual::number(38,2), '999,999,990.00'))  || '\n'
    || '  Budget                    $'
       || trim(to_char(n.brief_json:metrics:total_gms_sales:budget::number(38,2), '999,999,990.00'))  || '\n'
    || '  Variance                  '
       || trim(to_char(round(n.brief_json:metrics:total_gms_sales:var_pct::float * 100, 1), 'S990.0')) || '%' || '\n'
    || '  GM Profit                 $'
       || trim(to_char(n.brief_json:metrics:total_gm_profit:actual::number(38,2), '999,999,990.00'))
       || '  (' || trim(to_char(round(n.brief_json:metrics:total_gm_profit:var_pct::float * 100, 1), 'S990.0'))
       || '% vs budget)'                                                || '\n\n'
    || '  SALES BY AREA'                                                || '\n'
    || '  ------------------------------------------------------------'|| '\n'
    || coalesce(ar.block, '   • none')                                  || '\n\n'
    || '  PERIOD TO DATE (GMS sales vs budget)'                         || '\n'
    || '  ------------------------------------------------------------'|| '\n'
    || '   • MTD: $' || trim(to_char(n.brief_json:period_context:gms_sales_mtd::number(38,0), '999,999,990'))
       || ' vs $' || trim(to_char(n.brief_json:period_context:budget_gms_sales_mtd::number(38,0), '999,999,990'))
       || ' (' || trim(to_char(round(div0(
              n.brief_json:period_context:gms_sales_mtd::number(38,2)
            - n.brief_json:period_context:budget_gms_sales_mtd::number(38,2),
              nullif(n.brief_json:period_context:budget_gms_sales_mtd::number(38,2), 0)) * 100, 1), 'S990.0')) || '%)' || '\n'
    || '   • YTD: $' || trim(to_char(n.brief_json:period_context:gms_sales_ytd::number(38,0), '999,999,990'))
       || ' vs $' || trim(to_char(n.brief_json:period_context:budget_gms_sales_ytd::number(38,0), '999,999,990'))
       || ' (' || trim(to_char(round(div0(
              n.brief_json:period_context:gms_sales_ytd::number(38,2)
            - n.brief_json:period_context:budget_gms_sales_ytd::number(38,2),
              nullif(n.brief_json:period_context:budget_gms_sales_ytd::number(38,2), 0)) * 100, 1), 'S990.0')) || '%)' || '\n\n'
    || '  TOP BUDGET DRIVERS'                                          || '\n'
    || '  ------------------------------------------------------------'|| '\n'
    || coalesce(mv.block, '   • none')                                 || '\n\n'
    || '  WATCH ITEMS'                                                 || '\n'
    || '  ------------------------------------------------------------'|| '\n'
    || coalesce(wt.block, '   • none')                                 || '\n'
    || '════════════════════════════════════════════════════════════'
        as analyst_brief
from n
left join watch  wt on n.report_date = wt.report_date
left join movers mv on n.report_date = mv.report_date
left join areas  ar on n.report_date = ar.report_date
