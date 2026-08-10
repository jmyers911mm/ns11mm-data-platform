-- Marts report: long/unpivoted Today's Sales serving shape (intraday actuals per line item)
-- ---------------------------------------------------------------------------
-- Domain: retail (intraday)
-- Grain:  one row per report_date x hour_of_day x key_facility x line_item_code
--
-- Tidy Today's Sales presentation: unpivots rpt_today_sales_powerbi into one
-- long shape with the report's non-additive ratios resolved as
-- numerator/denominator components in SQL. Sibling of rpt_retail_report_long,
-- minus the budget side — the Today's Sales report has NO goals, so there are
-- no budget_* columns. Feeds the Power BI Today's Sales matrix, which joins
-- dim_today_sales_line_item for line labels/order (areas section by the row's
-- key_facility via dim_facility, hours on rows within each area).
-- NOTE: ratio rows carry numerator/denominator (never a pre-divided ratio) so
-- Power BI re-computes ratio-of-sums at any grain (hour, area, day total).
-- Stub lines (Store Visitors, Attendance, Totes Sold, Conversion, Capture,
-- Totes % of guests) emit typed NULL rows: there is no intraday visitor feed
-- and the tote SKU is unflagged — the seed marks those 'Stub'.
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

{#- Additive lines: code -> wrapper column. -#}
{% set additive_lines = [
    ('SALES', 'sales'),
    ('PROFIT', 'profit'),
    ('QTY_SOLD', 'units'),
    ('TICKET_COUNT', 'transactions')
] %}
{#- Ratio lines: code -> numerator column, denominator column. -#}
{% set ratio_lines = [
    ('AVG_SALE', 'sales', 'transactions'),
    ('AVG_QTY', 'units', 'transactions')
] %}
{#- Stub lines: no intraday visitor feed (store visitors / attendance and the
    conversion / capture ratios built on them); tote SKU unflagged (totes).
    Emitted as typed NULL until the feeds land. -#}
{% set stub_lines = [
    'STORE_VISITORS', 'ATTENDANCE', 'TOTES_SOLD',
    'CONVERSION', 'CAPTURE', 'TOTES_PCT_GUESTS'
] %}

with w as (
    select * from {{ ref('rpt_today_sales_powerbi') }}
)

{% for code, col in additive_lines %}
{% if not loop.first %}union all{% endif %}
select
    report_date, hour_of_day, key_facility,
    '{{ code }}' as line_item_code,
    cast({{ col }} as number(38,4)) as amount,
    cast(null as number(38,4)) as numerator,
    cast(null as number(38,4)) as denominator
from w
{% endfor %}
{% for code, num, den in ratio_lines %}
union all
select
    report_date, hour_of_day, key_facility,
    '{{ code }}' as line_item_code,
    cast(null as number(38,4)) as amount,
    cast({{ num }} as number(38,4)) as numerator,
    cast({{ den }} as number(38,4)) as denominator
from w
{% endfor %}
{% for code in stub_lines %}
union all
select
    report_date, hour_of_day, key_facility,
    '{{ code }}' as line_item_code,
    cast(null as number(38,4)) as amount,
    cast(null as number(38,4)) as numerator,
    cast(null as number(38,4)) as denominator
from w
{% endfor %}
