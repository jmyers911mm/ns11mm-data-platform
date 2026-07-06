/*
  rpt_ticket_sales
  Sources: fct_ticket_sales + dim_date + dim_ticket_type + dim_payment_method + dim_gate + dim_customer
  STATUS: Awaiting RAW data. Logic migrated from POC. Updated refs to production column names.
*/

{{ config(enabled=false,materialized='table') }}

select
    ts.transaction_id,
    ts.transaction_date,
    dd_txn.day_of_week_name                                as purchase_day_name,
    dd_txn.month_name                                      as purchase_month,
    dd_txn.fiscal_year                                     as purchase_fiscal_year,
    dd_txn.is_weekend                                      as purchased_on_weekend,
    ts.scan_date,
    dd_scan.day_of_week_name                               as scan_day_name,
    dd_scan.is_weekend                                     as scanned_on_weekend,
    ts.ticket_type_id                                      as ticket_type,
    dt.ticket_type_name,
    dt.visitor_category                                    as ticket_visitor_category,
    dt.standard_price                                      as ticket_standard_price,
    dt.pricing_tier,
    dt.is_free_admission,
    ts.quantity,
    ts.unit_price,
    ts.total_amount,
    ts.is_discounted,
    ts.discount_amount,
    ts.payment_method,
    pm.payment_method_name,
    pm.payment_category,
    ts.entry_gate,
    dg.gate_name,
    dg.location                                            as gate_location,
    dg.is_members_only                                     as entered_members_gate,
    ts.customer_id,
    c.full_name                                            as customer_name,
    c.customer_segment,
    c.membership_type,
    ts.is_valid_scan                                       as was_scanned,
    ts.utilization_status,
    ts.purchase_to_entry_hours                             as hours_purchase_to_entry,
    ts.visitors_admitted
from {{ ref('fct_ticket_sales') }} ts
left join {{ ref('dim_date') }}           dd_txn on ts.transaction_date = dd_txn.date_id
left join {{ ref('dim_date') }}           dd_scan on ts.scan_date = dd_scan.date_id
left join {{ ref('dim_ticket_type') }}    dt      on ts.ticket_type_id = dt.ticket_type_id
left join {{ ref('dim_payment_method') }} pm      on ts.payment_method = pm.payment_method_id
left join {{ ref('dim_gate') }}           dg      on ts.entry_gate = dg.gate_id
left join {{ ref('dim_customer') }}       c       on ts.customer_id = c.customer_id
