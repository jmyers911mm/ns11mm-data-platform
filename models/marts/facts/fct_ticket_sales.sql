/*
  fct_ticket_sales
  Sources: int_pos_tickets, int_ticket_scans, dim_customer
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{ config(enabled=false,materialized='table', cluster_by=['transaction_date', 'ticket_type_id']) }}

with tickets as (
    select * from {{ ref('int_pos_tickets') }}
),

scan_summary as (
    select
        scan_id                                             as transaction_id,
        scan_date,
        gate_id                                             as entry_gate,
        is_valid_scan,
        visitor_count
    from {{ ref('int_ticket_scans') }}
),

customer_lookup as (
    select customer_id, primary_email, primary_phone
    from {{ ref('dim_customer') }}
)

select
    t.transaction_id,
    t.transaction_date,
    s.scan_date,
    t.ticket_type_id,
    t.visitor_category,
    t.quantity,
    t.unit_price,
    t.total_amount,
    t.is_discounted,
    t.discount_amount,
    t.discount_code,
    t.payment_method,
    t.gate_id,
    s.entry_gate,
    s.is_valid_scan,
    s.visitor_count                                         as visitors_admitted,
    datediff('hour', t.transaction_date, coalesce(s.scan_date, t.transaction_date)) as purchase_to_entry_hours,
    t.customer_email,
    t.customer_phone,
    t.has_email,
    t.has_phone,
    coalesce(ce.customer_id, cp.customer_id)               as customer_id,
    current_timestamp()                                     as _loaded_at
from tickets t
left join scan_summary   s  on t.transaction_id = s.transaction_id
left join customer_lookup ce on t.customer_email = ce.primary_email and t.customer_email is not null
left join customer_lookup cp on t.customer_phone = cp.primary_phone and t.customer_phone is not null and ce.customer_id is null
