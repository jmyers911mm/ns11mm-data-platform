-- Marts dimension: dim_retail_line_item — Retail Performance Report line-item metadata + display config
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain: one row per line_item_code
--
-- Twin of dim_dpr_line_item. Maps each Retail Performance Report line to its
-- selling-area section, display order, indent, number format, availability
-- status, and (for ratio lines) the numerator/denominator source measures.
-- Drives section grouping and layout for the Power BI Retail report; the
-- ratio components resolve in rpt_retail_report_long (ADR-004).
--
-- Source: retail_line_items (dbt seed)

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
    facility_group,
    key_facility,
    num_source,
    den_source,
    current_timestamp()         as _loaded_at
from {{ ref('retail_line_items') }}
