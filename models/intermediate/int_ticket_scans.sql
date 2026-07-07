-- Intermediate: ticket scan/usage events from gateway for gate admission counts
-- Co-authored with CoCo

{{ config(materialized='view') }}

select
    usage_id                                        as scan_id,
    use_time::date                                  as scan_date,
    acp_id                                          as gate_id,
    facility_id,
    quantity                                        as visitor_count,
    status_code in (0, 1)                           as is_valid_scan,
    entry_method,
    is_override,
    _loaded_at                                      as _extracted_at
from {{ ref('stg_gateway__usage') }}
where use_time is not null
