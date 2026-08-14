-- Marts dimension: dim_retail_analysis_line_item — Retail Analysis Report line-item metadata + display config
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain: one row per line_item_code
--
-- Twin of dim_retail_line_item and dim_carts_line_item. Maps each Retail
-- Analysis Report line to its printed measure block, display order, indent,
-- number format, availability status, and (for ratio lines) the numerator/
-- denominator source measures on fct_retail_analysis. Drives section grouping
-- and layout for the Power BI Retail Analysis report; the ratio components
-- resolve in rpt_retail_analysis_report_long (ADR-004).
--
-- The legacy workbook's thirteen sheets are calendar years, not sections, so
-- they are absent from this catalog by design -- the year is a dim_date slicer
-- (see rpt_retail_analysis_report_long).
--
-- Source: retail_analysis_line_items (dbt seed)

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
from {{ ref('retail_analysis_line_items') }}
