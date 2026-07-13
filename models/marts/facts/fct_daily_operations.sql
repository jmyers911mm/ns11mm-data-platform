-- Marts fact: daily museum operations (ticket sales + gate scans + retail)
-- ---------------------------------------------------------------------------
-- Domain: operations
-- Grain:  one row per visit_date
--
-- Full-outer-joins daily ticket sales (int_pos_tickets) and gate scans
-- (int_ticket_scans) into a single day-grain operations fact: visitors admitted,
-- valid/rejected scans, active gates, ticket transactions/revenue/discounts,
-- identified buyers, and a total_revenue rollup. Incremental merge on visit_date
-- (append_new_columns), clustered by visit_date, tagged daily / critical.
-- NOTE: retail_transactions, retail_revenue, retail_discounts and
-- retail_revenue_per_visitor are hardcoded 0 placeholders pending the CounterPoint
-- retail join, so total_revenue currently equals ticket_revenue. Feeds
-- ml_visitor_forecast_training.
--
-- ADR-004: all business logic lives here, not in Power BI.

{{
    config(
        enabled=true,
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
    where _extracted_at > (select max(_loaded_at) from {{ this }})
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
    where _extracted_at > (select max(_loaded_at) from {{ this }})
    {% endif %}
    group by 1
)

select
    coalesce(t.visit_date, s.visit_date)                    as visit_date,
    coalesce(s.total_visitors_admitted, 0)                  as total_visitors,
    coalesce(s.valid_scans, 0)                              as valid_scans,
    coalesce(s.rejected_scans, 0)                           as rejected_scans,
    coalesce(s.gates_active, 0)                             as gates_active,
    coalesce(t.ticket_transactions, 0)                      as ticket_transactions,
    coalesce(t.tickets_sold, 0)                             as tickets_sold,
    coalesce(t.ticket_revenue, 0)                           as ticket_revenue,
    coalesce(t.ticket_discounts, 0)                         as ticket_discounts,
    coalesce(t.identified_visitors, 0)                      as identified_ticket_buyers,
    0                                                       as retail_transactions,
    0                                                       as retail_revenue,
    0                                                       as retail_discounts,
    coalesce(t.ticket_revenue, 0)                           as total_revenue,
    0                                                       as retail_revenue_per_visitor,
    current_timestamp()                                     as _loaded_at
from ticket_sales t
full outer join scans s on t.visit_date = s.visit_date
