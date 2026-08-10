-- Marts dimension: dim_attendance_line_item — Attendance Report line-item metadata + display config
-- ---------------------------------------------------------------------------
-- Domain: attendance
-- Grain: one row per line_item_code
--
-- Twin of dim_today_sales_line_item. Maps each Attendance Report line to its
-- section, display order, indent, number format, and availability status.
-- All five lines are additive counts, so num_source / den_source are carried
-- NULL; facility_group / key_facility are NULL because the report has no
-- facility axis (the Sensource feed is pre-aggregated by named area).
-- The three Sensource-backed lines (Memorial Only, Museum Store, Museum
-- Store (at Vesey)) are marked Stub until sensordata lands. Drives layout
-- for the Power BI Attendance Report; also covers the single-figure Daily
-- Attendance Report, which binds to the MUS_ATTENDANCE line (ADR-004).
--
-- Source: attendance_line_items (dbt seed)

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
from {{ ref('attendance_line_items') }}
