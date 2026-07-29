-- models/marts/reports/rpt_retail_report_long.sql
-- Tidy Retail Performance presentation: one row per (report_date, line_item_code)
-- carrying BOTH actual and budget (goal), with the report's non-additive ratios
-- resolved as numerator/denominator components in SQL (ADR-004: no business logic
-- in Power BI). Power BI joins to dim_retail_line_item for section/layout and to
-- dim_date for the period columns (Current Day / SDLY / WTD / MTD / QTD / YTD),
-- and uses one display measure per scenario. Twin of rpt_dpr_report_long.
--
--   amount / numerator / denominator                          -> ACTUAL (rpt_retail_powerbi)
--   budget_amount / budget_numerator / budget_denominator     -> BUDGET (rpt_retail_budget_daily)
--
-- Ratio rows carry numerator/denominator (never a pre-divided ratio) so Power BI
-- re-computes ratio-of-sums at any period grain. Visitor-based ratios resolve to
-- NULL until the Sensource feed lands (visitor_count stub = 0); the line-item
-- seed marks those 'Stub'. Attendance (the report's Attendance row and the
-- Revenue/Visitor denominators) is cross-domain: actual from FCT_DAILY_PERFORMANCE
-- (mus_attendance), goal from the retail forecast's museum_attendance.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

{#- ------------------------------------------------------------------ -#}
{#- Area map. Each selling area lists its additive lines (code suffix -> -#}
{#- wrapper column) and ratio lines (suffix -> numerator, denominator). -#}
{#- 'attendance' as a num/den source resolves to the per-date attendance -#}
{#- value (actual mus_attendance / budget museum_attendance).            -#}
{% set areas = [
  {'prefix':'MUSEUM_STORE',  'fac':1003,
     'additive':[('GROSS_MERCH_SALES','net_sales'),('GROSS_MARGIN_PROFIT','net_profit'),('DONATION_ASK','donations'),('CUSTOMERS','transactions'),('VISITORS','visitor_count')],
     'ratios':[('CAPTURE_RATE','visitor_count','attendance'),('CONVERSION_RATE','transactions','visitor_count'),('AVG_DAILY_SALE','net_sales','transactions'),('REV_PER_VISITOR','net_sales','attendance')] },
  {'prefix':'MEMORIAL_CARTS','fac':1020,
     'additive':[('GROSS_MERCH_SALES','net_sales'),('GROSS_MARGIN_PROFIT','net_profit'),('DONATIONS','donations'),('CUSTOMERS','transactions')],
     'ratios':[('CONVERSION_RATE','transactions','visitor_count'),('AVG_DAILY_SALE','net_sales','transactions'),('REV_PER_VISITOR','net_sales','attendance')] },
  {'prefix':'MUSEUM_CAFE',   'fac':4007,
     'additive':[('SALES','net_sales'),('PROFIT','net_profit'),('DONATION_ASK','donations'),('TRANSACTIONS','transactions')],
     'ratios':[('CONVERSION_RATE','transactions','visitor_count'),('AVG_SALE','net_sales','transactions'),('REV_PER_VISITOR','net_sales','attendance')] },
  {'prefix':'ECOMMERCE',     'fac':1234,
     'additive':[('SALES','net_sales'),('GROSS_PROFIT','net_profit'),('DONATIONS','donations'),('ORDERS','ecom_orders')],
     'ratios':[('AVG_SALE','net_sales','ecom_orders'),('GROSS_PROFIT_PER_ORDER','net_profit','ecom_orders')] },
  {'prefix':'MUS_AG',        'fac':1060,
     'additive':[('PROFIT','net_profit'),('UNITS_SOLD','net_units')],
     'ratios':[('REV_PER_VISITOR','net_sales','attendance'),('CONVERSION_RATE','net_units','attendance')] }
] %}

with
-- Per-date attendance (cross-domain). Same value across facilities on a day.
att_actual as (
    select cast(date_key as date) as report_date, sum(mus_attendance) as attendance
    from {{ ref('fct_daily_performance') }}
    group by 1
),
att_budget as (
    select report_date, max(museum_attendance) as attendance
    from {{ ref('rpt_retail_budget_daily') }}
    group by 1
),

-- Actuals per (date, facility) + the day's attendance
act as (
    select w.*, aa.attendance
    from {{ ref('rpt_retail_powerbi') }} w
    left join att_actual aa on w.report_date = aa.report_date
),
-- Budget/goal per (date, facility) + the day's attendance goal
bud as (
    select b.*, ab.attendance
    from {{ ref('rpt_retail_budget_daily') }} b
    left join att_budget ab on b.report_date = ab.report_date
),

-- =========================================================== ACTUAL long
actual_long as (
    -- Standalone Attendance line (museum attendance actual), facility-agnostic
    select report_date, cast(null as number) as key_facility,
           'ATTENDANCE' as line_item_code,
           cast(attendance as number(38,4)) as amount,
           cast(null as number(38,4)) as numerator, cast(null as number(38,4)) as denominator
    from att_actual

    {% for a in areas %}
      {# additive #}
      {% for suffix, col in a.additive %}
    union all
    select report_date, key_facility,
           '{{ a.prefix }}__{{ suffix }}' as line_item_code,
           cast({{ col }} as number(38,4)) as amount,
           cast(null as number(38,4)), cast(null as number(38,4))
    from act where key_facility = {{ a.fac }}
      {% endfor %}
      {# ratios: carry numerator/denominator, not a pre-divided value #}
      {% for suffix, num, den in a.ratios %}
    union all
    select report_date, key_facility,
           '{{ a.prefix }}__{{ suffix }}' as line_item_code,
           cast(null as number(38,4)) as amount,
           cast({{ num }} as number(38,4)) as numerator,
           cast({{ den }} as number(38,4)) as denominator
    from act where key_facility = {{ a.fac }}
      {% endfor %}
    {% endfor %}
),

-- =========================================================== BUDGET long
budget_long as (
    select report_date, cast(null as number) as key_facility,
           'ATTENDANCE' as line_item_code,
           cast(attendance as number(38,4)) as budget_amount,
           cast(null as number(38,4)) as budget_numerator, cast(null as number(38,4)) as budget_denominator
    from att_budget

    {% for a in areas %}
      {% for suffix, col in a.additive %}
    union all
    select report_date, key_facility,
           '{{ a.prefix }}__{{ suffix }}' as line_item_code,
           cast({{ col }} as number(38,4)) as budget_amount,
           cast(null as number(38,4)), cast(null as number(38,4))
    from bud where key_facility = {{ a.fac }}
      {% endfor %}
      {% for suffix, num, den in a.ratios %}
    union all
    select report_date, key_facility,
           '{{ a.prefix }}__{{ suffix }}' as line_item_code,
           cast(null as number(38,4)) as budget_amount,
           cast({{ num }} as number(38,4)) as budget_numerator,
           cast({{ den }} as number(38,4)) as budget_denominator
    from bud where key_facility = {{ a.fac }}
      {% endfor %}
    {% endfor %}
)

-- =========================================================== MERGE
select
    coalesce(a.report_date, b.report_date)       as report_date,
    coalesce(a.key_facility, b.key_facility)     as key_facility,
    coalesce(a.line_item_code, b.line_item_code) as line_item_code,
    a.amount,
    a.numerator,
    a.denominator,
    b.budget_amount,
    b.budget_numerator,
    b.budget_denominator
from actual_long a
full outer join budget_long b
    on  a.report_date    = b.report_date
    and a.line_item_code = b.line_item_code
    and coalesce(a.key_facility, -1) = coalesce(b.key_facility, -1)
