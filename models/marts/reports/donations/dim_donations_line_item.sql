-- Marts dimension: dim_donations_line_item — Donations Analysis Report line-item metadata + display config
-- ---------------------------------------------------------------------------
-- Domain: donations
-- Grain: one row per line_item_code
--
-- Twin of dim_retail_line_item and dim_dpr_line_item. Maps each Donations
-- Analysis Report line to its section, display order, indent, number format,
-- additive-vs-ratio type, availability status, the facility it belongs to, and
-- (for ratio lines) the numerator/denominator source measures. Drives section
-- grouping and layout for the Power BI Donations report; the ratio components
-- resolve in rpt_donations_report_long (ADR-004 — never in DAX, never a stored
-- quotient).
--
-- Availability semantics on this report: 'Partial' means the platform produces
-- the line from the donation CATEGORY at the right facility because legacy's
-- 911dw.dim_item_descr SKU whitelist is not staged and its surrogate keys
-- cannot be resolved. 'Stub' is a typed NULL with a stated cause.
--
-- Source: donations_line_items (dbt seed)

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
from {{ ref('donations_line_items') }}
