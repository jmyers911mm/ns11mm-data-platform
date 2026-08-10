-- Marts dimension: dim_tracker_line_item — Memorial & Museum Daily Tracker line-item metadata + display config
-- ---------------------------------------------------------------------------
-- Domain: DPR / cross-domain
-- Grain: one row per line_item_code
--
-- Twin of dim_dpr_line_item. Maps each Tracker scorecard line to its section,
-- display order, indent, number format, availability status, and (for ratio
-- lines) the numerator/denominator source measures. Drives layout for the
-- Power BI Memorial & Museum Daily Tracker; the ratio components resolve in
-- rpt_tracker_report_long (ADR-004). The Memorial-vs-Museum REVENUE split
-- (Total Memorial/Museum Revenue and both per-cap ratios) is an open
-- business-rule seam — marked 'Stub' until the split rule is decided.
--
-- Source: tracker_line_items (dbt seed)

{{ config(materialized='table', tags=['daily', 'critical']) }}

select
    line_item_code              as line_item_key,
    line_item_code,
    sort_order,
    section,
    section_sort_order,
    line_item,
    indent,
    format,
    value_type,
    availability,
    num_source,
    den_source,
    current_timestamp()         as _loaded_at
from {{ ref('tracker_line_items') }}
