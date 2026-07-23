{{ config(materialized='view') }}

-- Silver intermediate: retail visitor counts + ecommerce orders (STUB)
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per business_date x key_facility
--
-- Holds the two measures the Retail Performance Report needs that do NOT come
-- from CounterPoint:
--   1. Sensource / Atrium visitor counts  -> conversion-rate + rev-per-visitor
--   2. Shopify ecommerce order counts      -> ecom_total_orders
--
-- STUB STATUS: both sources are not yet ingested (sensordata seed + Shopify
-- pipeline / ADR-008). This model reads empty stub seeds so the fact and report
-- compile and the join seam exists today; it populates once those feeds land.
-- Base tables to seed: sensordata (ServerManager), fact_shopify_orders / Shopify.

{% set ecom_key_facility = 1234 %}   {# Ecommerce facility (see seed_facility_area) #}

with sensource as (
    -- Real Sensource feed: entries per facility per day = the visitor count.
    select
        cast(business_date as date)                 as date_key,
        key_facility,
        sum(num_entry)                              as visitor_count
    from {{ ref('stg_sensource__visitors') }}
    group by 1, 2
),

shopify as (
    -- Ecom orders map to the Ecommerce facility.
    select
        cast(business_date as date)                 as date_key,
        {{ ecom_key_facility }}                     as key_facility,
        count(distinct order_id)                    as ecom_orders
    from {{ ref('stg_shopify__orders') }}
    group by 1
),

combined as (
    select
        coalesce(s.date_key, e.date_key)            as date_key,
        coalesce(s.key_facility, e.key_facility)    as key_facility,
        coalesce(s.visitor_count, 0)                as visitor_count,
        coalesce(e.ecom_orders, 0)                  as ecom_orders
    from sensource s
    full outer join shopify e
      on s.date_key = e.date_key
     and s.key_facility = e.key_facility
)

select * from combined
