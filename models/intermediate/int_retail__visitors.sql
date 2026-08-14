-- Silver intermediate: retail visitor counts + ecommerce orders
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per date_key x key_facility (REPORTING facility)
--
-- Holds the two measures the Retail Performance Report needs that do NOT come
-- from CounterPoint: Sensource visitor counts (capture / conversion /
-- per-visitor denominators) and Shopify ecommerce order counts. The visitor
-- leg joins seed_sensource_facility_map, which does three things the old model
-- did none of: it translates the sensor-side facility id into the REPORTING
-- key_facility the marts join on, it names which measure column that facility
-- reports on (num_entry vs num_exit vs passes_scanned), and it names which
-- WRITER the row reads (source_system). Feeds fct_retail_daily,
-- int_attendance__sensource, and through them the retail, carts and attendance
-- serving stacks.
--
-- Legacy lineage: 911dw.fact_visitors (t_fact_visitors -> the Sensource API
-- leg, t_fact_museum_passes_scanned -> the Gateway leg),
-- 911dw.fact_shopify_orders.
-- NOTE (two writers, separate rows): 911dw.fact_visitors is blended at grain
-- (key_date, key_facility, acp) and the two writers land on DIFFERENT rows.
-- acp = 0 is the Sensource API leg (num_entry / num_exit populated,
-- passes_scanned 0); acp = a gate id is the Gateway leg (passes_scanned
-- populated, num_entry / num_exit NULL). The seed's source_system distinguishes
-- them, and the sensource leg is filtered to acp_id = 0 explicitly. The Gateway
-- rows carry NULL entry/exit so the filter is arithmetically harmless today --
-- it is here to make the leg separation legible and to guard against a future
-- writer landing a non-zero acp on the Sensource leg.
-- NOTE (8.7.0 re-source): the Gateway leg's passes_scanned is the LEGACY scan
-- count. 8.7.0 recomputes that measure in int_ticket_scans under the legacy
-- validity rule (code 0 adds, code 11 subtracts, Gateway facility 13 excluded)
-- and re-sources this leg to it, so one measure has one authority (ADR-021).
-- It cannot move earlier: int_ticket_scans resolves the ACP -> facility path
-- only as of 8.7.0; before that it returns the raw usage.facility_id (7, not
-- 1006) and the join would not resolve.
-- STATUS: Sensource leg is LIVE (feed landed 1.6.2; the facility crosswalk that
-- made it reachable landed 8.4.0). Shopify leg still reads an unpopulated
-- source and returns no rows -- ecom_orders is 0 until ADR-008 lands.
-- SCOPE NOTE: entry-vs-exit is a per-facility property, not a preference --
-- Museum Store counts entries, Vesey counts exits. Changing a facility's
-- measure_column changes a certified denominator; route via ADR-005
-- (owner: Gennady Zaritsky).
--
-- ADR-021 ratio rule: additive counts only; every ratio built on these divides
-- at display grain from carried numerator + denominator.

{{ config(materialized='view') }}

{% set ecom_key_facility = 1234 %}   {# Ecommerce facility (see seed_facility_area) #}

with sensource as (
    select * from {{ ref('stg_sensource__visitors') }}
),

facility_map as (
    select * from {{ ref('seed_sensource_facility_map') }}
),

shopify as (
    select * from {{ ref('stg_shopify__orders') }}
),

-- The rows of the crosswalk this model is entitled to read: the two legs that
-- land in 911dw.fact_visitors, and only those with a reporting home. The
-- memorial_feed row reads a different table entirely (stg_memorial__attendance,
-- consumed by int_attendance__sensource); is_reporting = FALSE rows are
-- declared sensors with no verified reporting facility (1008, 1009) and are
-- deliberately not published — assert_sensource_facilities_resolve reports
-- their volume so they are visible rather than silently dropped.
visitor_map as (
    select
        sensource_facility,
        reporting_facility,
        measure_column,
        source_system
    from facility_map
    where source_system in ('sensource', 'gateway_scan')
      and is_reporting
),

-- Sensor grain -> reporting facility grain. The inner join is the filter: a
-- feed facility with no reporting crosswalk row is not a reporting facility.
-- The CASE is conditional aggregation over the seeded measure name, not a
-- mapping of its own -- the enumerable mapping lives in the seed.
sensource_mapped as (
    select
        cast(s.business_date as date)                   as date_key,
        m.reporting_facility                            as key_facility,
        sum(
            case m.measure_column
                when 'num_entry'      then s.num_entry
                when 'num_exit'       then s.num_exit
                when 'passes_scanned' then s.passes_scanned
            end
        )                                               as visitor_count
    from sensource s
    inner join visitor_map m
        on s.key_facility = m.sensource_facility
       -- Leg separation, per the seed's own source_system.
       and (
               (m.source_system = 'sensource'    and s.acp_id = 0)
            or  m.source_system = 'gateway_scan'
           )
    group by 1, 2
),

-- Ecom orders map to the Ecommerce facility.
ecom as (
    select
        cast(business_date as date)                     as date_key,
        {{ ecom_key_facility }}                         as key_facility,
        count(distinct order_id)                        as ecom_orders
    from shopify
    group by 1
),

combined as (
    select
        coalesce(s.date_key, e.date_key)                as date_key,
        coalesce(s.key_facility, e.key_facility)        as key_facility,
        coalesce(s.visitor_count, 0)                    as visitor_count,
        coalesce(e.ecom_orders, 0)                      as ecom_orders
    from sensource_mapped s
    full outer join ecom e
      on s.date_key = e.date_key
     and s.key_facility = e.key_facility
)

select
    date_key,
    key_facility,
    visitor_count,
    ecom_orders
from combined
