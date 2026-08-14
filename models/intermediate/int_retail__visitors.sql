-- Silver intermediate: retail visitor counts + ecommerce orders
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per date_key x key_facility (REPORTING facility)
--
-- Holds the two measures the Retail Performance Report needs that do NOT come
-- from CounterPoint: visitor counts (capture / conversion / per-visitor
-- denominators) and Shopify ecommerce order counts. The visitor leg joins
-- seed_sensource_facility_map, which does three things the pre-8.4.0 model did
-- none of: it translates the feed-side facility id into the REPORTING
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
-- them, and the sensource leg is filtered to acp_id = 0 explicitly.
--
-- SCOPE NOTE (ADR-005 gate, 8.7.0) — owner Chris Wogas. The GATEWAY leg is
-- re-sourced. Through 8.6.0 it read 911dw.fact_visitors.passes_scanned, which is
-- the LEGACY scan count. 8.7.0 recomputes that same measure in int_ticket_scans
-- under the legacy validity rule -- usage code 0 adds, code 11 subtracts,
-- Gateway facility 13 excluded, resolved through the ACP path -- so continuing
-- to read the seeded column would leave one measure with two authorities that
-- disagree by construction (ADR-021). This leg now sums
-- int_ticket_scans.net_visitor_count at the seeded gateway_scan facility, so the
-- Atrium visitor count on the carts and retail reports moves by exactly the same
-- delta as museum attendance on the DPR, which is the point.
--
-- This could not be done in 8.4.0: int_ticket_scans resolved the ACP -> facility
-- path only as of this release. Before it, key_facility was the raw
-- usage.facility_id (7, not 1006) and the join to the crosswalk would not have
-- resolved at all.
--
-- STATUS: visitor legs are LIVE (feed landed 1.6.2; the facility crosswalk that
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

scans as (
    select * from {{ ref('int_ticket_scans') }}
),

facility_map as (
    select * from {{ ref('seed_sensource_facility_map') }}
),

shopify as (
    select * from {{ ref('stg_shopify__orders') }}
),

-- The Sensource API leg of 911dw.fact_visitors: entries and exits at acp 0.
-- is_reporting = FALSE rows are declared sensors with no verified reporting
-- facility (1008, 1009) and are deliberately not published --
-- assert_sensource_facilities_resolve reports their volume.
sensource_map as (
    select
        sensource_facility,
        reporting_facility,
        measure_column
    from facility_map
    where source_system = 'sensource'
      and is_reporting
),

-- The Gateway pass-scan leg. measure_column is 'passes_scanned' on these rows
-- and names the legacy measure; the VALUE now comes from int_ticket_scans.
gateway_map as (
    select
        sensource_facility,
        reporting_facility
    from facility_map
    where source_system = 'gateway_scan'
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
                when 'num_entry' then s.num_entry
                when 'num_exit'  then s.num_exit
            end
        )                                               as visitor_count
    from sensource s
    inner join sensource_map m
        on s.key_facility = m.sensource_facility
    where s.acp_id = 0
    group by 1, 2
),

-- Gate grain -> reporting facility grain. int_ticket_scans.key_facility is
-- already the resolved 911dw key (1006 / 5000 / 0), which is what the
-- crosswalk's gateway_scan rows are keyed on.
gateway_mapped as (
    select
        s.scan_date                                     as date_key,
        m.reporting_facility                            as key_facility,
        sum(s.net_visitor_count)                        as visitor_count
    from scans s
    inner join gateway_map m
        on s.key_facility = m.sensource_facility
    where s.is_counted_scan
      and s.scan_date is not null
    group by 1, 2
),

visitors as (
    select
        date_key,
        key_facility,
        sum(visitor_count)                              as visitor_count
    from (
        select date_key, key_facility, visitor_count from sensource_mapped
        union all
        select date_key, key_facility, visitor_count from gateway_mapped
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
        coalesce(v.date_key, e.date_key)                as date_key,
        coalesce(v.key_facility, e.key_facility)        as key_facility,
        coalesce(v.visitor_count, 0)                    as visitor_count,
        coalesce(e.ecom_orders, 0)                      as ecom_orders
    from visitors v
    full outer join ecom e
      on v.date_key = e.date_key
     and v.key_facility = e.key_facility
)

select
    date_key,
    key_facility,
    visitor_count,
    ecom_orders
from combined
