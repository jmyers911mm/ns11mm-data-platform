/*
  fct_ticket_availability
  Source: silver_ticket_inventory + dim_date
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{
    config(
        materialized='incremental',
        unique_key='availability_key',
        incremental_strategy='merge',
        cluster_by=['entry_date', 'ticket_type_id'],
        tags=['intraday', 'critical']
    )
}}

with inventory as (
    select * from {{ ref('silver_ticket_inventory') }}
    {% if is_incremental() %}
    where entry_date >= (select max(entry_date) - 7 from {{ this }})
    {% endif %}
),

date_attrs as (
    select date_id, day_of_week_name, day_of_week, is_weekend, month_name, fiscal_year
    from {{ ref('dim_date') }}
)

select
    i.inventory_key                                         as availability_key,
    i.entry_date,
    d.day_of_week_name                                      as day_name,
    d.day_of_week                                           as day_of_week_num,
    d.is_weekend,
    d.month_name,
    d.fiscal_year,
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
left join date_attrs d on i.entry_date = d.date_id
