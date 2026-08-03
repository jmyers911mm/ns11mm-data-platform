-- Marts dimension: dim_today_sales_line_item — Today's Sales report line-item metadata + display config
-- ---------------------------------------------------------------------------
-- Domain: retail (intraday)
-- Grain: one row per line_item_code
--
-- Twin of dim_retail_line_item. Maps each Today's Sales report line to its
-- section, display order, indent, number format, availability status, and
-- (for ratio lines) the numerator/denominator source measures. Line items
-- apply to every selling area (the area comes from the fact row's
-- key_facility, not the line item), so facility_group / key_facility are
-- carried NULL. Drives layout for the Power BI Today's Sales report; the
-- ratio components resolve in rpt_today_sales_report_long (ADR-004).
--
-- Source: today_sales_line_items (dbt seed)

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
from {{ ref('today_sales_line_items') }}
