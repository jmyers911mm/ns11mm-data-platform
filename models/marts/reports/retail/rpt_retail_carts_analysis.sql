-- Marts report: Retail Carts Analysis Report
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain: one row per date_key (Memorial Carts area)
--
-- Presentation view for report.retail_carts_analysis_report. A memorial-carts
-- lens on fct_retail_daily. The capture / per-cap denominator is NOT fixed:
-- the legacy workbook switches it by calendar year, and that switch is now
-- read from seed_carts_denominator_rule rather than hardcoded --
--   2019: (memorial visitors less 25%) less museum visitors  -- plaza-only
--         foot traffic the carts actually convert
--   2020: memorial visitors, unadjusted
--   any other year: NO RULE -> denominator NULL -> ratios NULL
-- The fall-through is legacy behaviour, not an omission: the CASE in
-- t_retail_cart_analysis_tabs.sql:19-22 has no ELSE, while the report's own
-- filter (:35-36) selects `key_date >= '2020-07-04'` with no upper bound. Every
-- printed row from 2021 onward has therefore had blank capture rate, blank
-- profit-per-cap and blank sales-per-cap for five years.
--
-- Memorial and museum visitor counts come from the day-level attendance
-- denominators on fct_retail_daily (Sensource, via int_retail__ratio_
-- components), not from visitor_count at the Memorial Carts facility -- no
-- Sensource sensor reports at 1020, which is why those lines read zero before
-- 8.5.0.
--
-- Legacy lineage: t_retail_cart_analysis_tabs -> 911dw.fact_retail_analysis
-- (written by t_fact_mus_store_analysis, step "Table input 2").
-- SCOPE NOTE: ADR-005 GATED on two points. (1) Which denominator applies from
-- 2021 onward -- legacy answers NULL and this model reproduces that; adding a
-- row to seed_carts_denominator_rule is the whole fix once a rule is chosen.
-- (2) adj_visitors is the raw legacy expression and may go negative when
-- museum attendance exceeds 75% of memorial attendance; the pre-8.5.0 model
-- clamped it at zero, which legacy never did. Owners: Gennady Zaritsky,
-- Chris Wogas -- see DECISION_MEMO.md.
-- ADR-004: no logic in Power BI; it reads this view as-is.

{{ config(materialized='view') }}

with carts as (
    select
        date_key, date_value, is_commemoration_day,
        net_sales, net_profit, transactions
    from {{ ref('fct_retail_daily') }}
    where area_name = 'Memorial Carts'
),

attendance as (
    -- Day-level denominators, identical across facility rows on a given day.
    select
        date_value,
        max(memorial_attendance)                        as mem_visitors,
        max(museum_attendance)                          as mus_visitors
    from {{ ref('fct_retail_daily') }}
    group by 1
),

denominator_rule as (
    select * from {{ ref('seed_carts_denominator_rule') }}
),

joined as (
    select
        c.date_key,
        c.date_value,
        c.is_commemoration_day,
        c.net_sales                                     as sales_mem_cart,
        c.net_profit                                    as profit_mem_cart,
        c.transactions                                  as mem_cart_customers,
        a.mem_visitors,
        a.mus_visitors,
        -- t_retail_cart_analysis_tabs.sql:15 and :17, verbatim
        (a.mem_visitors - 0.25 * a.mem_visitors)                        as mem_visitors_less_25,
        ((a.mem_visitors - 0.25 * a.mem_visitors) - a.mus_visitors)     as adj_visitors,
        r.denominator_rule
    from carts c
    left join attendance a       on c.date_value = a.date_value
    left join denominator_rule r on year(c.date_value) = r.calendar_year
),

final as (
    select
        date_key,
        date_value,
        is_commemoration_day,
        sales_mem_cart,
        profit_mem_cart,
        mem_cart_customers,
        mem_visitors,
        mem_visitors_less_25,
        mus_visitors,
        adj_visitors,
        denominator_rule,
        -- The year-switched denominator. Unknown year -> NULL -> ratios NULL.
        case denominator_rule
            when 'adjusted_memorial_less_museum' then adj_visitors
            when 'memorial_visitors'             then mem_visitors
        end                                             as capture_denominator
    from joined
)

select
    date_key,
    date_value,
    is_commemoration_day,
    sales_mem_cart,
    profit_mem_cart,
    mem_cart_customers,
    mem_visitors,
    mem_visitors_less_25,
    mus_visitors,
    adj_visitors,
    denominator_rule,
    capture_denominator,
    -- Non-additive ratios at query grain. rpt_carts_report_long carries the
    -- components instead and deliberately does not read these.
    profit_mem_cart / nullif(sales_mem_cart, 0)         as profit_margin,
    sales_mem_cart  / nullif(mem_cart_customers, 0)     as avg_sale,
    mem_cart_customers / nullif(capture_denominator, 0) as capture_rate,
    profit_mem_cart / nullif(capture_denominator, 0)    as profit_per_cap,
    sales_mem_cart  / nullif(capture_denominator, 0)    as sales_per_cap
from final
