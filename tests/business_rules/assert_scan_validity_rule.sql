-- Test (business_rule): only Status 0 / Code 0 and Status 0 / Code 11 scans count
-- Severity: error — this is the certified passes-scanned definition
-- (t_fact_museum_passes_scanned). A row here means int_ticket_scans admitted a
-- usage code the legacy rule drops, or credited an excluded facility, which
-- silently inflates every attendance figure and per-capita ratio downstream.

select
    scan_id,
    scan_date,
    status_code,
    usage_code,
    key_facility,
    is_facility_excluded,
    scan_sign,
    net_visitor_count
from {{ ref('int_ticket_scans') }}
where is_counted_scan
  and (
        status_code::varchar <> '0'
     or usage_code::varchar not in ('0', '11')
     or is_facility_excluded
     or scan_sign not in (-1, 1)
     or net_visitor_count <> visitor_count * scan_sign
  )
