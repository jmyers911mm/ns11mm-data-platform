-- Rename fiscal_year to year for simplified calendar dimensions
-- Co-authored with CoCo
-- Marts fact: ticket availability by entry date and ticket type
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (capacity)
-- Grain:  one row per entry_date + ticket_type (availability_key)
-- STATUS: Awaiting RAW data. Logic migrated from POC.
--
-- Publishes int_ticket_inventory joined to dim_date for calendar attributes.
-- Incremental merge on availability_key with a 7-day reprocessing lookback;
-- clustered by entry_date, ticket_type; tagged intraday / critical.
-- NOTE: inherits the proxy-capacity caveat from int_ticket_inventory. Feeds
-- ml_ticket_demand_features.
--
-- ADR-004: all business logic lives upstream in dbt, not in Power BI.

{{
    config(
        enabled=true,
        materialized='incremental',
        unique_key='availability_key',
        incremental_strategy='merge',
        cluster_by=['entry_date', 'ticket_type'],
        tags=['intraday', 'critical']
    )
}}

with inventory as (
    select * from {{ ref('int_ticket_inventory') }}
    {% if is_incremental() %}
    where entry_date >= (select max(entry_date) - 7 from {{ this }})
    {% endif %}
),

date_attrs as (
    select date_key, day_of_week_name, day_of_week, is_weekend, month_name, year_number as year
    from {{ ref('dim_date') }}
)

select
    i.inventory_key                                         as availability_key,
    i.entry_date,
    d.day_of_week_name                                      as day_name,
    d.day_of_week                                           as day_of_week_num,
    d.is_weekend,
    d.month_name,
    d.year,
    i.entry_window_start,
    i.entry_window_end,
    i.ticket_type_id                                        as ticket_type,
    i.ticket_capacity,
    i.tickets_reserved,
    i.tickets_available,
    i.utilization_pct,
    i.demand_level,
    i.is_override,
    current_timestamp()                                     as _loaded_at
from inventory i
left join date_attrs d on i.entry_date = d.date_key
