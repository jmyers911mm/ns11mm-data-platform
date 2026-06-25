/*
  ml_ticket_no_show_features
  Sources: fct_ticket_sales + dim_date
  STATUS: Awaiting RAW data. Logic migrated from POC.
  Predicts probability a sold ticket will not be scanned.
*/

{{ config(materialized='table', tags=['daily', 'non-critical']) }}

with tickets as (
    select
        transaction_id, transaction_date, ticket_type_id as ticket_type,
        visitor_category, quantity, total_amount, is_discounted, discount_amount,
        payment_method, customer_id, is_valid_scan as was_scanned,
        utilization_status, purchase_to_entry_hours,
        extract(hour from transaction_date::timestamp)     as purchase_hour,
        extract(dow from transaction_date)                 as day_of_week_num,
        case when extract(dow from transaction_date) in (0,6) then 1 else 0 end as is_weekend
    from {{ ref('fct_ticket_sales') }}
),

customer_history as (
    select
        customer_id,
        count(*)                                           as prior_ticket_count,
        sum(case when not is_valid_scan then 1 else 0 end) as prior_no_shows,
        div0(sum(case when not is_valid_scan then 1 else 0 end)::float, count(*)) as historical_no_show_rate
    from {{ ref('fct_ticket_sales') }}
    where customer_id is not null
    group by customer_id
),

ticket_type_stats as (
    select
        ticket_type_id as ticket_type,
        avg(case when not is_valid_scan then 1.0 else 0.0 end) as type_no_show_rate,
        avg(purchase_to_entry_hours)                       as type_avg_lead_time
    from {{ ref('fct_ticket_sales') }}
    group by ticket_type_id
)

select
    t.transaction_id, t.transaction_date, t.ticket_type, t.visitor_category,
    t.quantity, t.total_amount, t.is_discounted, t.payment_method,
    t.customer_id, t.purchase_hour, t.day_of_week_num, t.is_weekend,
    case when t.customer_id is null then 1 else 0 end      as is_anonymous,
    coalesce(ch.prior_ticket_count, 0)                     as customer_prior_ticket_count,
    coalesce(ch.prior_no_shows, 0)                         as customer_prior_no_shows,
    coalesce(ch.historical_no_show_rate, 0)                as customer_historical_no_show_rate,
    coalesce(tts.type_no_show_rate, 0)                     as ticket_type_no_show_rate,
    coalesce(tts.type_avg_lead_time, 0)                    as ticket_type_avg_lead_time,
    t.purchase_to_entry_hours                              as days_advance_purchase,
    case when not t.was_scanned then 1 else 0 end          as label_no_show,
    current_timestamp()                                    as _feature_computed_at
from tickets t
left join customer_history  ch  on t.customer_id = ch.customer_id
left join ticket_type_stats tts on t.ticket_type  = tts.ticket_type
