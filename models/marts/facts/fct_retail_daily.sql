-- Marts fact: retail daily (facility grain, non-additive-across-category inputs)
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain: one row per date_key x key_facility
--
-- Companion to fct_retail_performance. Holds the measures that live at the
-- FACILITY (not category) grain: transaction/customer counts and visitor
-- counts, plus facility-level sales/profit/donation totals rolled up from the
-- category fact for ratio convenience. This is the grain the Retail
-- Performance Report's ratios operate on (conversion rate, rev-per-visitor,
-- average sale, per-cap donations).
--
-- 8.4.0: the facility-day spine is a UNION of the category fact and the
-- visitor feed, not the category fact alone. The Atrium (1030) is a
-- visitor-only area with no CounterPoint sales, so a perf-only spine dropped
-- its rows entirely and rpt_retail_carts_analysis's museum-visitor lens was
-- empty by construction. The visitor leg is restricted to facilities
-- dim_facility knows, which keeps the attendance-only reporting facilities
-- (Vesey 1001, Memorial Plaza 2000) in the attendance chain and out of the
-- retail fact.
--
-- Replaces legacy 911dw.fact_num_tickets + the facility rollup of fact_retail.
-- ADR-004: additive measures only; ratios computed in rpt_retail_performance.

{{ config(materialized='table') }}

with perf as (
    select
        date_value                          as date_key,
        key_facility,
        sum(net_sales)                      as net_sales,
        sum(net_profit)                     as net_profit,
        sum(net_units)                      as net_units,
        sum(donations)                      as donations
    from {{ ref('fct_retail_performance') }}
    group by 1, 2
),

customers as (
    select date_key, key_facility, transactions
    from {{ ref('int_retail__customers') }}
),

visitors as (
    select date_key, key_facility, visitor_count, ecom_orders
    from {{ ref('int_retail__visitors') }}
),

facility as (
    select * from {{ ref('dim_facility') }}
),

-- Facility-day spine: everything that sold plus everything that was counted
-- at a facility the retail vocabulary recognizes.
spine as (
    select date_key, key_facility from perf
    union
    select v.date_key, v.key_facility
    from visitors v
    inner join facility f on v.key_facility = f.key_facility
),

final as (
    select
        dd.date_key,
        s.date_key                                          as date_value,
        s.key_facility,
        coalesce(f.area_name, 'Unmapped ' || s.key_facility) as area_name,
        f.area_group,
        dd.is_commemoration_day,

        -- Facility-level additive measures
        coalesce(p.net_sales, 0)                            as net_sales,
        coalesce(p.net_profit, 0)                           as net_profit,
        coalesce(p.net_units, 0)                            as net_units,
        coalesce(p.donations, 0)                            as donations,
        coalesce(c.transactions, 0)                         as transactions,
        coalesce(v.visitor_count, 0)                        as visitor_count,
        coalesce(v.ecom_orders, 0)                          as ecom_orders      -- stub until Shopify

    from spine s
    inner join {{ ref('dim_date') }} dd on s.date_key = dd.date_key
    left join perf      p on s.date_key = p.date_key and s.key_facility = p.key_facility
    left join customers c on s.date_key = c.date_key and s.key_facility = c.key_facility
    left join visitors  v on s.date_key = v.date_key and s.key_facility = v.key_facility
    left join facility  f on s.key_facility = f.key_facility
)

select * from final
