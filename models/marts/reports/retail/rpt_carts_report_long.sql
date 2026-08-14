-- Marts report: long/unpivoted Retail Carts Analysis serving shape (daily carts measures per line item)
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per report_date x line_item_code
--
-- Tidy Carts Analysis presentation: unpivots rpt_retail_carts_analysis into
-- one long shape with the report's non-additive ratios resolved as
-- numerator/denominator components in SQL. Sibling of
-- rpt_retail_report_long, minus the budget side — the Carts Analysis has no
-- goals. Feeds the Power BI Carts Analysis table/matrix, which joins
-- dim_carts_line_item for labels/order/format and dim_date for the legacy
-- workbook's Month/Day grouping (monthly subtotals are ratio-of-sums in
-- DAX, never pre-divided daily ratios averaged).
-- NOTE: ratio rows carry numerator/denominator (never a pre-divided ratio)
-- so Power BI re-computes ratio-of-sums at any grain (day, month, season).
-- The pre-divided ratio columns on rpt_retail_carts_analysis remain for the
-- legacy day-grain view; this model deliberately does not read them.
-- 8.5.0: the ratio denominator is capture_denominator, the year-switched
-- legacy denominator resolved upstream from seed_carts_denominator_rule — not
-- adj_visitors, which is only the 2019 form. adj_visitors is still published
-- as its own printed line (ADJ_VISITORS), because the workbook prints it.
-- Rows outside the seeded years carry a NULL denominator and the ratio is
-- blank, as it is on the legacy workbook.
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

{#- Additive lines: code -> source expression on rpt_retail_carts_analysis.
    mem_visitors_less_25 is the legacy printed intermediate (75% of memorial
    visitors); adj_visitors is the 2019 capture/per-cap denominator. -#}
{% set additive_lines = [
    ('MEM_VISITORS', 'mem_visitors'),
    ('MEM_VISITORS_LESS_25', 'mem_visitors_less_25'),
    ('MUS_VISITORS', 'mus_visitors'),
    ('ADJ_VISITORS', 'adj_visitors'),
    ('CART_CUSTOMERS', 'mem_cart_customers'),
    ('GROSS_PROFIT', 'profit_mem_cart'),
    ('SALES', 'sales_mem_cart')
] %}
{#- Ratio lines: code -> numerator column, denominator column. -#}
{% set ratio_lines = [
    ('CAPTURE_RATE', 'mem_cart_customers', 'capture_denominator'),
    ('AVG_SALE', 'sales_mem_cart', 'mem_cart_customers'),
    ('PROFIT_PER_CAP', 'profit_mem_cart', 'capture_denominator'),
    ('SALES_PER_CAP', 'sales_mem_cart', 'capture_denominator')
] %}

with w as (
    select * from {{ ref('rpt_retail_carts_analysis') }}
)

{% for code, expr in additive_lines %}
{% if not loop.first %}union all{% endif %}
select
    date_value as report_date,
    is_commemoration_day,
    '{{ code }}' as line_item_code,
    cast({{ expr }} as number(38,4)) as amount,
    cast(null as number(38,4)) as numerator,
    cast(null as number(38,4)) as denominator
from w
{% endfor %}
{% for code, num, den in ratio_lines %}
union all
select
    date_value as report_date,
    is_commemoration_day,
    '{{ code }}' as line_item_code,
    cast(null as number(38,4)) as amount,
    cast({{ num }} as number(38,4)) as numerator,
    cast({{ den }} as number(38,4)) as denominator
from w
{% endfor %}
