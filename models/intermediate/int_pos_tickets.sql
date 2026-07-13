-- Silver intermediate: daily POS ticket transactions from Gateway tickets
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (POS)
-- Grain:  one row per ticket_id (transaction), where sold_at is not null
--
-- Flattens stg_gateway__tickets to a transaction line: sale date, plu, quantity,
-- total_amount (price * quantity), and discount. Feeds the ticket_sales CTE in
-- fct_daily_operations.
-- NOTE: customer_email / has_email are stopgaps derived from customer_id
-- (customer_id cast to varchar), pending a real CRM identity join.
--
-- ADR-001: reads only from stg_ (RAW is upstream and immutable).
-- ADR-004: all business logic lives here, not in Power BI.

{{ config(materialized='view') }}

with tickets as (
    select
        ticket_id,
        sold_at,
        ticket_date,
        plu,
        quantity,
        price,
        discount_amt,
        customer_id,
        order_no,
        sales_channel_id,
        _loaded_at
    from {{ ref('stg_gateway__tickets') }}
    where sold_at is not null
)

select
    t.ticket_id                                     as transaction_id,
    t.sold_at::date                                 as transaction_date,
    t.plu,
    t.quantity,
    t.price * t.quantity                            as total_amount,
    coalesce(t.discount_amt, 0)                     as discount_amount,
    t.customer_id,
    t.customer_id::varchar                          as customer_email,
    t.customer_id is not null                       as has_email,
    t.sales_channel_id,
    t._loaded_at                                    as _extracted_at
from tickets t
