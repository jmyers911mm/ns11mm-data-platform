/*
  silver_pos_tickets
  Source: stg_gateway__transactions + stg_gateway__customers
  Grain: one row per ticket transaction
  Logic migrated from POC with customer email/phone resolved via Gateway customers table.
*/

{{
    config(
        materialized='incremental',
        unique_key='transaction_id',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        cluster_by=['transaction_date'],
        tags=['daily', 'critical']
    )
}}

with transactions as (
    select * from {{ ref('stg_gateway__transactions') }}
    {% if is_incremental() %}
    where _extracted_at > (select max(_extracted_at) from {{ this }})
    {% endif %}
),

customers as (
    select customer_id, email, phone
    from {{ ref('stg_gateway__customers') }}
)

select
    t.transaction_id,
    t.transaction_date,
    t.ticket_type_id,
    case
        when t.ticket_type_id like '%Adult%'  then 'Adult'
        when t.ticket_type_id like '%Child%'  then 'Child'
        when t.ticket_type_id like '%Senior%' then 'Senior'
        when t.ticket_type_id like '%Member%' then 'Member'
        when t.ticket_type_id like '%School%' then 'School Group'
        when t.ticket_type_id like '%Family%' then 'Family'
        else 'Other'
    end                                                     as visitor_category,
    t.quantity,
    t.unit_price,
    t.total_amount,
    t.discount_code,
    t.discount_amount,
    case when t.discount_amount > 0 then true else false end as is_discounted,
    t.payment_method,
    t.gate_id,
    t.session_id,
    t.sales_channel,
    lower(trim(c.email))                                    as customer_email,
    trim(c.phone)                                           as customer_phone,
    case when c.email is not null then true else false end   as has_email,
    case when c.phone is not null then true else false end   as has_phone,
    t.order_id,
    t.last_modified_at,
    t.hashdiff,
    t._extracted_at
from transactions t
left join customers c on t.customer_id = c.customer_id
