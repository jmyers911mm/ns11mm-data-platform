-- Intermediate: daily POS ticket transactions from gateway orders and tickets
-- Co-authored with CoCo

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
