-- Marts dimension: dim_retail_print_line — one row per PRINTED line of the Retail Performance Report
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain: one row per print_code
--
-- The Retail Performance Report prints scenario as ROWS, not columns: each
-- metric appears as a "... Goal" row, a "... Actual" row, and — for selected
-- metrics only — a shaded "Variance" row (see the legacy PDF, 911dw.dayofdata
-- .arialnormal.prpt). This dimension is the printed-row catalog: 69 rows in
-- the exact printed order, each pointing at the underlying metric_code in
-- dim_retail_line_item / rpt_retail_report_periods plus the scenario to read
-- from it.
--
-- Relationship to dim_retail_line_item: that dim stays the METRIC catalog
-- (one row per measured thing, actual+goal side by side, used by
-- rpt_retail_report_long and rpt_retail_report_periods). This dim is the
-- PRESENTATION catalog (one row per printed line). Both are needed; neither
-- replaces the other.
--
-- line_item_display: Power BI's "sort by column" requires a 1:1 mapping
-- between the sorted column and its sort column, but printed labels repeat
-- ('Variance' appears 8x, 'Revenue / Museum Visitor' 4x). This column
-- appends N trailing spaces (N = occurrence index) so every label is
-- technically unique while rendering identically in a matrix row header —
-- which lets line_item_display sort by print_order natively. DO NOT "clean
-- up" the padding: it is load-bearing. line_item keeps the raw label for any
-- consumer that needs it.
--
-- Source: retail_print_lines (dbt seed)

{{ config(materialized='table', tags=['daily', 'critical']) }}

with s as (
    select * from {{ ref('retail_print_lines') }}
)

select
    print_code                  as print_line_key,
    print_code,
    print_order,
    section,
    section_sort_order,
    line_item,
    -- unique-but-identical-looking label for Power BI sort-by-column
    line_item
      || repeat(' ', row_number() over (partition by line_item order by print_order) - 1)
                                as line_item_display,
    indent,
    format,
    scenario,
    metric_code,
    availability,
    current_timestamp()         as _loaded_at
from s
