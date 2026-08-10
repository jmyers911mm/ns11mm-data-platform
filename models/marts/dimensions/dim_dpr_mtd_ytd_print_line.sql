-- Marts dimension: dim_dpr_mtd_ytd_print_line — printed rows of the DPR MTD/YTD workbooks
-- ---------------------------------------------------------------------------
-- Domain: DPR
-- Grain: one row per print_code
--
-- Printed-row catalog for the DPR "Month to Date" and "Year to Date" Excel
-- variants (both print the SAME rows; only the period window differs, which is
-- why one catalog serves both). Twin of dim_retail_print_line.
--
-- Unlike the daily DPR, these workbooks compare ACTUAL to PRIOR YEAR (not to
-- budget), and they break donations out individually rather than rolling them
-- into the two donation composites the daily report prints — which is why they
-- need their own catalog rather than reusing dpr_line_items.
--
-- line_item_display appends occurrence-index trailing spaces so repeated
-- labels ('Attendance' in both Memorial and Museum, 'Customers', 'Average
-- Sale', ...) are unique for Power BI's sort-by-column, which requires a 1:1
-- label -> sort mapping, while rendering identically. The padding is
-- load-bearing — do not remove it.
--
-- Source: dpr_mtd_ytd_print_lines (dbt seed)

{{ config(materialized='table', tags=['daily', 'critical']) }}

with s as (
    select * from {{ ref('dpr_mtd_ytd_print_lines') }}
)

select
    print_code                  as print_line_key,
    print_code,
    print_order,
    section,
    section_sort_order,
    line_item,
    line_item
      || repeat(' ', row_number() over (partition by line_item order by print_order) - 1)
                                as line_item_display,
    indent,
    format,
    metric_code,
    availability,
    current_timestamp()         as _loaded_at
from s
