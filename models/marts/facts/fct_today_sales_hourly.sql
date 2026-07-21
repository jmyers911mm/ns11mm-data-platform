{{ config(materialized='table') }}

-- Marts fact: today's sales, hourly
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per date_key x hour_of_day x key_facility
--
-- Backs report.hourly_retail_report (Today's Sales). Now sourced from the real
-- same-day CounterPoint feed (stg_counterpoint__todays_retail) instead of the
-- stub. store_id is mapped to key_facility via seed_retail_store_facility;
-- transactions = count(distinct doc_id); units = quantity_sold. ADR-004:
-- additive only.

with today as (
    select
        business_date,
        hour_of_day,
        store_id,
        doc_id,
        quantity_sold,
        sales,
        cost
    from {{ ref('stg_counterpoint__todays_retail') }}
),

store_facility as (
    select store_id, key_facility from {{ ref('seed_retail_store_facility') }}
),

mapped as (
    select
        cast(t.business_date as date)               as date_key,
        t.hour_of_day,
        coalesce(sf.key_facility, -1)               as key_facility,
        t.doc_id,
        t.quantity_sold,
        t.sales,
        t.cost
    from today t
    left join store_facility sf on t.store_id = sf.store_id
),

hourly as (
    select
        date_key,
        hour_of_day,
        key_facility,
        count(distinct doc_id)                      as transactions,
        sum(quantity_sold)                          as units,
        sum(sales)                                  as sales,
        sum(cost)                                   as cost,
        sum(sales) - sum(cost)                      as profit
    from mapped
    group by 1, 2, 3
),

area as (
    select key_facility, area_name from {{ ref('seed_facility_area') }}
)

select
    dd.date_key,
    h.date_key                          as date_value,
    h.hour_of_day,
    h.key_facility,
    coalesce(a.area_name, 'Unmapped')   as area_name,
    h.transactions,
    h.units,
    h.sales,
    h.cost,
    h.profit
from hourly h
inner join {{ ref('dim_date') }} dd on h.date_key = dd.date_key
left join area a on h.key_facility = a.key_facility
