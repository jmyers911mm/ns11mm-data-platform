/*
  fct_ticket_utilization
  Sources: silver_pos_tickets + silver_ticket_scans
  STATUS: Awaiting RAW data. Deprecated in POC (2026-07-01) — retained here
  as it may be useful for operational reporting. Evaluate before publishing.
  Logic migrated from POC.
*/

{{ config(enabled=false,materialized='table', tags=['daily', 'non-critical']) }}

with tickets as (
    select
        transaction_id, transaction_date, ticket_type_id, visitor_category,
        quantity, total_amount, is_discounted, has_email, _extracted_at
    from {{ ref('silver_pos_tickets') }}
),

scans as (
    select
        scan_id                                             as ticket_transaction_id,
        count(*)                                            as total_scan_attempts,
        count(case when is_valid_scan then 1 end)           as valid_scans,
        count(case when not is_valid_scan then 1 end)       as rejected_scans,
        min(scan_date)                                      as first_scan_date,
        max(scan_date)                                      as last_scan_date,
        min(case when is_valid_scan then gate_id end)       as entry_gate,
        sum(case when is_valid_scan then visitor_count else 0 end) as visitors_admitted
    from {{ ref('silver_ticket_scans') }}
    group by scan_id
)

select
    t.transaction_id,
    t.transaction_date,
    t.ticket_type_id,
    t.visitor_category,
    t.quantity,
    t.total_amount,
    t.is_discounted,
    t.has_email,
    case when s.ticket_transaction_id is not null then true else false end as was_scanned,
    coalesce(s.visitors_admitted, 0)                        as visitors_admitted,
    s.entry_gate,
    s.first_scan_date,
    s.total_scan_attempts,
    s.valid_scans,
    s.rejected_scans,
    case
        when s.ticket_transaction_id is null then 'Unused'
        when s.valid_scans > 0 then 'Used'
        else 'Rejected'
    end                                                     as utilization_status,
    current_timestamp()                                     as _loaded_at
from tickets t
left join scans s on t.transaction_id = s.ticket_transaction_id
