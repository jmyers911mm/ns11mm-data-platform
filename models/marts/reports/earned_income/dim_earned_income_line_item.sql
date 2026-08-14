-- Marts dimension: dim_earned_income_line_item — Earned Income Variance Report line-item metadata + display config
-- ---------------------------------------------------------------------------
-- Domain: earned income
-- Grain: one row per line_item_code
--
-- Twin of dim_dpr_line_item and dim_retail_analysis_line_item. Maps each
-- printed Earned Income Variance Report line to its section, display order,
-- indent, number format, additive-vs-ratio behaviour, honest availability
-- state, and (for the one ratio line) the numerator/denominator source
-- measures on fct_earned_income. Drives section grouping and layout for the
-- Power BI Earned Income Variance report; the ratio components resolve in
-- rpt_earned_income_variance_report_long (ADR-004).
--
-- The legacy workbook's thirteen sheets are calendar years 2014-2026, not
-- sections, so they are absent from this catalog by design -- the year is a
-- dim_date slicer (see rpt_earned_income_variance_report_long).
--
-- The nineteen legacy *_diff columns are likewise absent: variance is not a
-- line item, it is the difference between the two scenarios each line already
-- carries, taken at display grain.
--
-- Source: earned_income_line_items (dbt seed)

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
from {{ ref('earned_income_line_items') }}
