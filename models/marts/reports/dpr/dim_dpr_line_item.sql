-- Marts dimension: dim_dpr_line_item — DPR report line-item metadata and display config
-- ---------------------------------------------------------------------------
-- Domain: DPR
-- Grain: one row per line_item_code
--
-- Maps each DPR measure to its report section, display order, formatting, and
-- availability status. Used by rpt_daily_performance_report (and the Power BI
-- DPR) to drive section grouping, indent level, number formatting, and to flag
-- measures that are partial or gapped.
--
-- Source: dpr_line_items (dbt seed)

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
    current_timestamp()         as _loaded_at
from {{ ref('dpr_line_items') }}
