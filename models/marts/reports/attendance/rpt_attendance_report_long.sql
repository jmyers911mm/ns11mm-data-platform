-- Marts report: long/unpivoted Attendance Report serving shape (daily attendance counts per line item)
-- ---------------------------------------------------------------------------
-- Domain: attendance
-- Grain:  one row per report_date x line_item_code
--
-- Tidy Attendance Report presentation: unpivots rpt_attendance into one long
-- shape. Sibling of rpt_today_sales_report_long, minus ratios and budget —
-- every printed line is an additive count and the report has no goals, so
-- numerator/denominator/budget_* columns are omitted entirely rather than
-- carried NULL. Feeds the Power BI Attendance Report matrix/line charts,
-- which join dim_attendance_line_item for line labels/order and dim_date for
-- period rollups (WTD/MTD/YTD in DAX, never in SQL). Also serves the Daily
-- Attendance Report: a card on the MUS_ATTENDANCE line at latest date.
-- Sensource-backed lines (MEMORIAL_ONLY, MUSEUM_STORE, MUSEUM_STORE_VESEY)
-- flow the stub's coalesced zeros; the seed marks them 'Stub' so Power BI
-- greys them until sensordata lands.
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

{#- Additive lines: code -> source column on rpt_attendance. -#}
{% set additive_lines = [
    ('MEM_ATTENDANCE', 'memorial_attendance'),
    ('MUS_ATTENDANCE', 'museum_attendance'),
    ('MEMORIAL_ONLY', 'memorial_only'),
    ('MUSEUM_STORE', 'museum_store'),
    ('MUSEUM_STORE_VESEY', 'museum_store_vesey')
] %}

with w as (
    select * from {{ ref('rpt_attendance') }}
)

{% for code, col in additive_lines %}
{% if not loop.first %}union all{% endif %}
select
    date_value as report_date,
    is_commemoration_day,
    '{{ code }}' as line_item_code,
    cast({{ col }} as number(38,4)) as amount
from w
{% endfor %}
