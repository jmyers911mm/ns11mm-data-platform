{{ config(materialized='table') }}

-- Marts fact: retail daily (facility grain, non-additive-across-category inputs)
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per date_key x key_facility
--
-- Companion to fct_retail_performance. Holds the measures that live at the
-- FACILITY (not category) grain: transaction/customer counts and visitor
-- counts, plus facility-level sales/profit/donation totals rolled up from the
-- category fact for ratio convenience. This is the grain the Retail
-- Performance Report's ratios operate on (conversion rate, rev-per-visitor,
-- average sale, per-cap donations).
--
-- Replaces legacy 911dw.fact_num_tickets + the facility rollup of fact_retail.
-- ADR-004: additive measures only; ratios computed in rpt_retail_performance.

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

final as (
    select
        dd.date_key,
        p.date_key                                          as date_value,
        p.key_facility,
        coalesce(f.area_name, 'Unmapped ' || p.key_facility) as area_name,
        f.area_group,
        dd.is_commemoration_day,

        -- Facility-level additive measures
        p.net_sales,
        p.net_profit,
        p.net_units,
        p.donations,
        coalesce(c.transactions, 0)                         as transactions,
        coalesce(v.visitor_count, 0)                        as visitor_count,   -- stub until Sensource
        coalesce(v.ecom_orders, 0)                          as ecom_orders      -- stub until Shopify

    from perf p
    inner join {{ ref('dim_date') }} dd on p.date_key = dd.date_key
    left join customers c on p.date_key = c.date_key and p.key_facility = c.key_facility
    left join visitors  v on p.date_key = v.date_key and p.key_facility = v.key_facility
    left join {{ ref('dim_facility') }} f on p.key_facility = f.key_facility
)

select * from final
