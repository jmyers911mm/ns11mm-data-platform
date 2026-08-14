-- Silver intermediate: retail ratio numerator/denominator components
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per date_key x key_facility
--
-- The single authoring site for the four non-additive retail ratios the Retail
-- Performance and Carts Analysis reports print. Every component is an ADDITIVE
-- column; no quotient is ever stored, so each ratio recomputes as a
-- ratio-of-sums at whatever grain the display asks for.
--
--   capture_rate    = store_entries      / museum_attendance
--   conversion_rate = transactions       / store_entries
--   sales_per_cap   = net_sales          / museum_attendance
--   profit_per_cap  = net_profit         / museum_attendance
--
-- Note conversion's denominator IS capture's numerator (store_entries). That
-- is the whole point of the 8.5.0 split: capture asks "what share of museum
-- visitors came through the store door", conversion asks "what share of the
-- people who came through the door bought something". Two questions, two
-- denominators, one column each -- not one metric with two names.
--
-- memorial_attendance is carried alongside for the Memorial Carts denominator;
-- it is not a numerator or denominator of any of the four pairs above.
--
-- Legacy lineage: t_fact_mus_store_analysis.sql:17-19 (capture_rate,
-- conversion_rate), :139-141 (per-cust/per-cap forms), t_fact_capture_
-- conversion_rate.sql (911dw.fact_capture_rate, 911dw.fact_conversion_rate).
-- SCOPE NOTE: ADR-005 GATED. museum_attendance here is the Sensource
-- passes-scanned measure at 1006+3000 (the legacy capture denominator), which
-- is NOT the same number as fct_daily_performance.mus_attendance (the DPR scan
-- component). Adopting this as the certified capture denominator changes a
-- published rate. Requires sign-off from Gennady Zaritsky and Chris Wogas --
-- see DECISION_MEMO.md.
--
-- ADR-021 ratio rule: carry numerator and denominator; divide once at display
-- grain. This model is the reason that rule is satisfiable for retail.

{{ config(materialized='view') }}

with visitors as (
    select * from {{ ref('int_retail__visitors') }}
),

customers as (
    select * from {{ ref('int_retail__customers') }}
),

performance as (
    select * from {{ ref('int_retail__performance') }}
),

attendance as (
    select * from {{ ref('int_attendance__sensource') }}
),

-- Facility-day rollup of the category-grain sales measures.
sales as (
    select
        date_key,
        key_facility,
        sum(net_sales)                                  as net_sales,
        sum(net_profit)                                 as net_profit
    from performance
    group by 1, 2
),

-- Facility-day spine: anything that sold, was counted, or was transacted.
spine as (
    select date_key, key_facility from sales
    union
    select date_key, key_facility from customers
    union
    select date_key, key_facility from visitors
),

components as (
    select
        s.date_key,
        s.key_facility,

        -- capture numerator / conversion denominator: door count at this area
        coalesce(v.visitor_count, 0)                    as store_entries,

        -- conversion numerator
        coalesce(c.transactions, 0)                     as transactions,

        -- per-cap numerators
        coalesce(sl.net_sales, 0)                       as net_sales,
        coalesce(sl.net_profit, 0)                      as net_profit,

        -- capture / per-cap denominator (day-level, repeated on every facility
        -- row so the pair travels together at the fact's grain)
        coalesce(a.museum_attendance, 0)                as museum_attendance,

        -- Memorial Carts denominator (not part of the four pairs above)
        coalesce(a.memorial_attendance, 0)              as memorial_attendance

    from spine s
    left join visitors   v  on s.date_key = v.date_key and s.key_facility = v.key_facility
    left join customers  c  on s.date_key = c.date_key and s.key_facility = c.key_facility
    left join sales      sl on s.date_key = sl.date_key and s.key_facility = sl.key_facility
    left join attendance a  on s.date_key = a.date_key
)

select
    date_key,
    key_facility,
    store_entries,
    transactions,
    net_sales,
    net_profit,
    museum_attendance,
    memorial_attendance
from components
