-- Silver intermediate: ticket demand features (presale lead time + temporal)
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (demand)
-- Grain:  one row per ticket_id (sold_at and ticket_date not null; ticket_date
--         guarded < 2030-01-01 to drop bad far-future dates)
--
-- Enriches each sold ticket with presale lead time (sold_at to ticket_date) and a
-- presale bucket, full entry-date and sale-time calendar parts, item/type via the
-- items join, revenue, purchase channel (online/onsite from sales_channel_id),
-- and usage/active flags. This is the base feature grain the demand and inventory
-- models roll up from.
-- NOTE: presale_lead_days can be negative (sold after the entry date, e.g. a
-- walk-up/retroactive sale). ticket_type_name falls back to plu when the item
-- lookup misses. Feeds int_ticket_inventory and fct_ticket_demand_forecast.
--
-- ADR-001: reads only from stg_ (RAW is upstream and immutable).
-- ADR-004: all business logic lives here, not in Power BI.

{{ config(materialized='view') }}

with tickets as (
    select
        ticket_id,
        sold_at,
        ticket_date,
        ticket_code,
        plu,
        product_no,
        quantity,
        price,
        status_code,
        use_count,
        customer_id,
        sales_channel_id,
        event_no
    from {{ ref('stg_gateway__tickets') }}
    where sold_at is not null
      and ticket_date is not null
      and ticket_date < '2030-01-01'
),

items as (
    select
        plu,
        item_name,
        description,
        kind
    from {{ ref('stg_gateway__items') }}
),

with_features as (
    select
        t.ticket_id,

        -- Timestamps
        t.sold_at,
        t.ticket_date,

        -- Presale lead time (negative = sold after entry date, e.g. walk-up retroactive)
        datediff('day', t.sold_at::date, t.ticket_date::date)   as presale_lead_days,
        datediff('hour', t.sold_at, t.ticket_date)              as presale_lead_hours,

        -- Presale bucket
        case
            when datediff('day', t.sold_at::date, t.ticket_date::date) <= 0 then 'same_day'
            when datediff('day', t.sold_at::date, t.ticket_date::date) = 1 then 'next_day'
            when datediff('day', t.sold_at::date, t.ticket_date::date) between 2 and 7 then '2_to_7_days'
            when datediff('day', t.sold_at::date, t.ticket_date::date) between 8 and 14 then '1_to_2_weeks'
            when datediff('day', t.sold_at::date, t.ticket_date::date) between 15 and 30 then '2_to_4_weeks'
            when datediff('day', t.sold_at::date, t.ticket_date::date) between 31 and 90 then '1_to_3_months'
            else '3_plus_months'
        end                                                     as presale_bucket,

        -- Entry date features
        t.ticket_date::date                                     as entry_date,
        dayofweek(t.ticket_date::date)                          as entry_dow,
        dayname(t.ticket_date::date)                            as entry_day_name,
        dayofyear(t.ticket_date::date)                          as entry_doy,
        weekofyear(t.ticket_date::date)                         as entry_week,
        month(t.ticket_date::date)                              as entry_month,
        quarter(t.ticket_date::date)                            as entry_quarter,
        year(t.ticket_date::date)                               as entry_year,
        case when dayofweek(t.ticket_date::date) in (0, 6)
             then true else false end                            as is_weekend,

        -- Sale time features
        t.sold_at::date                                         as sale_date,
        hour(t.sold_at)                                         as sale_hour,
        dayofweek(t.sold_at::date)                              as sale_dow,

        -- Entry time (hour from ticket_date if timestamp has time component)
        hour(t.ticket_date)                                     as entry_hour,

        -- Ticket classification
        t.plu,
        t.ticket_code,
        t.product_no,
        coalesce(i.item_name, t.plu)                            as ticket_type_name,
        i.kind                                                  as ticket_kind,

        -- Volume
        t.quantity,
        t.price,
        t.quantity * t.price                                    as revenue,

        -- Customer / channel
        t.customer_id,
        t.sales_channel_id,
        case when t.sales_channel_id is not null
             then 'online' else 'onsite' end                    as purchase_channel,

        -- Status
        t.status_code,
        case when t.use_count > 0 then true else false end      as was_used,
        case when t.status_code = 1 then true else false end    as is_active

    from tickets t
    left join items i on t.plu = i.plu
)

select * from with_features
