/*
  rpt_visitor_traffic
  Sources: fct_visitor_traffic + dim_date + dim_gate + fct_ticket_sales
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{ config(enabled=false,materialized='table') }}

select
    vt.scan_date,
    vt.scan_hour,
    dd.day_of_week_name                                    as day_name,
    dd.month_name,
    dd.fiscal_year,
    dd.is_weekend,
    dd.is_commemoration_day,
    vt.gate_id,
    dg.gate_name,
    dg.location                                            as gate_location,
    dg.is_members_only,
    dg.is_primary_entrance,
    vt.visitors_admitted,
    vt.total_scans,
    vt.valid_scan_count,
    vt.rejected_scan_count,
    vt.valid_scan_rate_pct,
    ts.tickets_for_gate,
    ts.ticket_utilization_rate
from {{ ref('fct_visitor_traffic') }} vt
left join {{ ref('dim_date') }}  dd on vt.scan_date = dd.date_id
left join {{ ref('dim_gate') }}  dg on vt.gate_id = dg.gate_id
left join (
    select
        entry_gate,
        scan_date,
        count(*)                                           as tickets_for_gate,
        div0(sum(case when is_valid_scan then 1 else 0 end), count(*)) as ticket_utilization_rate
    from {{ ref('fct_ticket_sales') }}
    where entry_gate is not null
    group by entry_gate, scan_date
) ts on vt.gate_id = ts.entry_gate and vt.scan_date = ts.scan_date
