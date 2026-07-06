/*
  fct_daily_operations
  Sources: int_pos_tickets, int_ticket_scans, int_pos_retail
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{
    config(
        enabled=false,
        unique_key='visit_date',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        cluster_by=['visit_date'],
        tags=['daily', 'critical']
    )
}}

with ticket_sales as (
    select
        transaction_date                                    as visit_date,
        count(distinct transaction_id)                      as ticket_transactions,
        sum(quantity)                                       as tickets_sold,
        sum(total_amount)                                   as ticket_revenue,
        sum(discount_amount)                                as ticket_discounts,
        count(distinct case when has_email then customer_email end) as identified_visitors
    from {{ ref('int_pos_tickets') }}
    {% if is_incremental() %}
    where _extracted_at > (select max(_extracted_at) from {{ this }})
    {% endif %}
    group by 1
),

scans as (
    select
        scan_date                                           as visit_date,
        sum(case when is_valid_scan then visitor_count else 0 end) as total_visitors_admitted,
        count(case when is_valid_scan then 1 end)           as valid_scans,
        count(case when not is_valid_scan then 1 end)       as rejected_scans,
        count(distinct gate_id)                             as gates_active
    from {{ ref('int_ticket_scans') }}
    {% if is_incremental() %}
    where _extracted_at > (select max(_extracted_at) from {{ this }})
    {% endif %}
    group by 1
),

retail as (
    select
        order_date                                          as visit_date,
        count(distinct order_id)                            as retail_transactions,
        sum(total_price)                                    as retail_revenue,
        sum(total_discounts)                                as retail_discounts
    from {{ ref('int_shopify') }}
    {% if is_incremental() %}
    where _extracted_at > (select max(_extracted_at) from {{ this }})
    {% endif %}
    group by 1
)

select
    coalesce(t.visit_date, s.visit_date, r.visit_date)     as visit_date,
    coalesce(s.total_visitors_admitted, 0)                  as total_visitors,
    coalesce(s.valid_scans, 0)                              as valid_scans,
    coalesce(s.rejected_scans, 0)                           as rejected_scans,
    coalesce(s.gates_active, 0)                             as gates_active,
    coalesce(t.ticket_transactions, 0)                      as ticket_transactions,
    coalesce(t.tickets_sold, 0)                             as tickets_sold,
    coalesce(t.ticket_revenue, 0)                           as ticket_revenue,
    coalesce(t.ticket_discounts, 0)                         as ticket_discounts,
    coalesce(t.identified_visitors, 0)                      as identified_ticket_buyers,
    coalesce(r.retail_transactions, 0)                      as retail_transactions,
    coalesce(r.retail_revenue, 0)                           as retail_revenue,
    coalesce(r.retail_discounts, 0)                         as retail_discounts,
    coalesce(t.ticket_revenue, 0) + coalesce(r.retail_revenue, 0) as total_revenue,
    div0(coalesce(r.retail_revenue, 0), nullif(coalesce(s.total_visitors_admitted, 0), 0)) as retail_revenue_per_visitor,
    current_timestamp()                                     as _loaded_at
from ticket_sales t
full outer join scans   s on t.visit_date = s.visit_date
full outer join retail  r on coalesce(t.visit_date, s.visit_date) = r.visit_date
