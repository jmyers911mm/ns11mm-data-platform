-- ===========================================================================
-- DPR Analyst Notes — formatted "brief card"
-- Source is MARTS.DPR_NARRATIVE (the base table), NOT the DPR_PBI_NARRATIVE
-- wrapper view: the card's Bottom-line and Top-drivers sections read brief_json,
-- which the display-only PBI view does not carry.
-- Latest day only by default; delete the WHERE in cte `n` to render every day.
-- Best viewed in Snowsight: click the analyst_brief cell to expand it.
-- ===========================================================================
with n as (
    select *
    from marts.dpr_narrative            -- <- base table (has brief_json)
    where report_date = (select max(report_date) from marts.dpr_narrative)
),

-- watch_items -> one bullet per line
watch as (
    select report_date,
           listagg('   • ' || value::string, '\n')
               within group (order by index) as block
    from n, lateral flatten(input => try_parse_json(to_varchar(n.watch_items)))
    group by report_date
),

-- top budget movers -> one bullet per driver, signed dollars + % vs budget
movers as (
    select report_date,
           listagg(
               '   • ' || value:line::string
               || ' — '
               || case when value:var_amount::number < 0 then '-$' else '$' end
               || trim(to_char(abs(value:var_amount::number), '999,999,990'))
               || ' (' || trim(to_char(round(value:var_pct::float * 100, 1), '990.0'))
               || '% vs budget)',
               '\n') within group (order by index) as block
    from n, lateral flatten(input => n.brief_json:top_budget_movers)
    group by report_date
)

select
    n.report_date,
       '════════════════════════════════════════════════════════════' || '\n'
    || '  DAILY PERFORMANCE REPORT · ANALYST NOTES'                     || '\n'
    || '  ' || n.brief_json:day_name::string || ', '
           || to_char(n.report_date, 'MON DD, YYYY')                    || '\n'
    || '════════════════════════════════════════════════════════════' || '\n\n'
    || '  ' || n.headline                                              || '\n\n'
    || '  BOTTOM LINE'                                                  || '\n'
    || '  ------------------------------------------------------------'|| '\n'
    || '  Total Estimated Revenue   $'
       || trim(to_char(n.brief_json:total_estimated_revenue:actual::number, '999,999,990.00')) || '\n'
    || '  Budget                    $'
       || trim(to_char(n.brief_json:total_estimated_revenue:budget::number, '999,999,990.00')) || '\n'
    || '  Variance                  '
       || trim(to_char(round(div0(
              n.brief_json:total_estimated_revenue:actual::number
            - n.brief_json:total_estimated_revenue:budget::number,
              n.brief_json:total_estimated_revenue:budget::number) * 100, 1), '990.0')) || '%  '
       || case when n.brief_json:total_estimated_revenue:actual::number
                    < n.brief_json:total_estimated_revenue:budget::number
               then '(behind budget)' else '(ahead of budget)' end       || '\n\n'
    || '  ANALYST NOTE'                                                 || '\n'
    || '  ------------------------------------------------------------'|| '\n'
    || '  ' || n.narrative                                             || '\n\n'
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
order by n.report_date desc;