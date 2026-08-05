-- Marts dimension: dim_carts_line_item — Retail Carts Analysis line-item metadata + display config
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain: one row per line_item_code
--
-- Twin of dim_retail_line_item for the Retail Carts Analysis report. Maps
-- each printed column of the legacy Carts Analysis workbook to a line item:
-- section, display order, number format, additive-vs-ratio, availability,
-- and — for ratio lines — the numerator/denominator source measures that
-- resolve in rpt_carts_report_long (ADR-004). The report is a single-area
-- lens, so facility_group/key_facility are fixed to Memorial Carts (1020).
-- Visitor-derived lines (visitors, adjusted denominator, capture, per-caps)
-- are marked Stub until Sensource lands — the legacy "adjusted memorial
-- visitor" denominator (memorial less 25%, less museum visitors) cannot be
-- computed from a stub without printing zeros as facts.
--
-- Source: carts_line_items (dbt seed)

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
from {{ ref('carts_line_items') }}
