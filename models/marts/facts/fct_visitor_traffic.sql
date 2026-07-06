/*
  fct_visitor_traffic
  Source: int_ticket_scans
  STATUS: Awaiting RAW data. Logic migrated from POC.
  Hourly gate-level visitor traffic.
*/

{{ config(enabled=false,materialized='table', cluster_by=['scan_date', 'gate_id']) }}

select
    scan_date || '-' || scan_hour || '-' || gate_id        as scan_date_hour_gate,
    scan_date,
    extract(hour from scan_date)                            as scan_hour,
    gate_id,
    dayname(scan_date)                                      as day_of_week,
    sum(case when is_valid_scan then visitor_count else 0 end) as visitors_admitted,
    count(*)                                                as total_scans,
    count(case when is_valid_scan then 1 end)               as valid_scan_count,
    count(case when not is_valid_scan then 1 end)           as rejected_scan_count,
    round(count(case when is_valid_scan then 1 end)::float
        / nullif(count(*), 0) * 100, 2)                    as valid_scan_rate_pct,
    current_timestamp()                                     as _loaded_at
from {{ ref('int_ticket_scans') }}
group by scan_date, gate_id
