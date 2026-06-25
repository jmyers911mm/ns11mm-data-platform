/*
  dim_payment_method
  Source: silver_pos_tickets + silver_pos_retail + ref_payment_methods seed
  STATUS: Awaiting RAW data.
  Logic migrated from POC.
*/

{{ config(materialized='table') }}

with from_silver as (
    select distinct payment_method as payment_method_id from {{ ref('silver_pos_tickets') }} where payment_method is not null
    union
    select distinct payment_method from {{ ref('silver_pos_retail') }} where payment_method is not null
),

from_seed as (
    select payment_method_id::varchar as payment_method_id, payment_method_name
    from {{ ref('ref_payment_methods') }}
)

select
    coalesce(s.payment_method_id, r.payment_method_id)         as payment_method_id,
    coalesce(r.payment_method_name, s.payment_method_id)       as payment_method_name,
    case coalesce(s.payment_method_id, r.payment_method_id)
        when 'Credit Card' then 'Card'
        when 'Debit Card'  then 'Card'
        when 'Cash'        then 'Cash'
        when 'Apple Pay'   then 'Digital'
        when 'Google Pay'  then 'Digital'
        else 'Other'
    end as payment_category,
    case coalesce(s.payment_method_id, r.payment_method_id)
        when 'Credit Card' then true
        when 'Debit Card'  then true
        when 'Apple Pay'   then true
        when 'Google Pay'  then true
        else false
    end as is_electronic,
    current_timestamp() as _loaded_at
from from_seed r
full outer join from_silver s on r.payment_method_id = s.payment_method_id
