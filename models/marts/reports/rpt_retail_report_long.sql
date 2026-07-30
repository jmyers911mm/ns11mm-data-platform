-- Marts report: long/unpivoted Retail Performance serving shape (actual + budget per line item)
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per report_date x key_facility x line_item_code
--
-- Tidy Retail Performance presentation: unpivots rpt_retail_powerbi (actual)
-- and rpt_retail_budget_daily (goal) into one long shape carrying BOTH
-- scenarios, with the report's non-additive ratios resolved as
-- numerator/denominator components in SQL. Twin of rpt_dpr_report_long. Feeds
-- the Power BI Retail Performance Report matrix, which joins
-- dim_retail_line_item for section/layout and dim_date for the period columns
-- (Current Day / SDLY / WTD / MTD / QTD / YTD).
-- NOTE: ratio rows carry numerator/denominator (never a pre-divided ratio) so
-- Power BI re-computes ratio-of-sums at any period grain. Visitor-based ratios
-- resolve to NULL until the Sensource feed lands (visitor_count stub = 0); the
-- line-item seed marks those 'Stub'. Attendance (the Attendance row and the
-- Revenue/Visitor denominators) is cross-domain: actual from
-- fct_daily_performance (mus_attendance), goal from the retail forecast's
-- museum_attendance.
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

{#- ------------------------------------------------------------------ -#}
{#- Area map. Each selling area lists its additive lines (code suffix -> -#}
{#- wrapper column) and ratio lines (suffix -> numerator, denominator). -#}
{#- 'attendance' as a num/den source resolves to the per-date attendance -#}
{#- value (actual mus_attendance / budget museum_attendance). Areas are  -#}
{#- selected by dim_facility.facility_group (the conformed name), never  -#}
{#- by raw key_facility numbers.                                         -#}
{% set areas = [
  {'prefix':'MUSEUM_STORE',  'fg':'museum_store',
     'additive':[('GROSS_MERCH_SALES','net_sales'),('GROSS_MARGIN_PROFIT','net_profit'),('DONATION_ASK','donations'),('CUSTOMERS','transactions'),('VISITORS','visitor_count')],
     'ratios':[('CAPTURE_RATE','visitor_count','attendance'),('CONVERSION_RATE','transactions','visitor_count'),('AVG_DAILY_SALE','net_sales','transactions'),('REV_PER_VISITOR','net_sales','attendance')] },
  {'prefix':'MEMORIAL_CARTS','fg':'memorial_carts',
     'additive':[('GROSS_MERCH_SALES','net_sales'),('GROSS_MARGIN_PROFIT','net_profit'),('DONATIONS','donations'),('CUSTOMERS','transactions')],
     'ratios':[('CONVERSION_RATE','transactions','visitor_count'),('AVG_DAILY_SALE','net_sales','transactions'),('REV_PER_VISITOR','net_sales','attendance')] },
  {'prefix':'MUSEUM_CAFE',   'fg':'museum_cafe',
     'additive':[('SALES','net_sales'),('PROFIT','net_profit'),('DONATION_ASK','donations'),('TRANSACTIONS','transactions')],
     'ratios':[('CONVERSION_RATE','transactions','visitor_count'),('AVG_SALE','net_sales','transactions'),('REV_PER_VISITOR','net_sales','attendance')] },
  {'prefix':'ECOMMERCE',     'fg':'ecommerce',
     'additive':[('SALES','net_sales'),('GROSS_PROFIT','net_profit'),('DONATIONS','donations'),('ORDERS','ecom_orders')],
     'ratios':[('AVG_SALE','net_sales','ecom_orders'),('GROSS_PROFIT_PER_ORDER','net_profit','ecom_orders')] },
  {'prefix':'MUS_AG',        'fg':'mus_ag',
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

-- Actuals per (date, facility) + the day's attendance + conformed facility name
act as (
    select w.*, aa.attendance, df.facility_group
    from {{ ref('rpt_retail_powerbi') }} w
    left join att_actual aa on w.report_date = aa.report_date
    left join {{ ref('dim_facility') }} df on w.key_facility = df.key_facility
),
-- Budget/goal per (date, facility) + the day's attendance goal + conformed facility name
bud as (
    select b.*, ab.attendance, df.facility_group
    from {{ ref('rpt_retail_budget_daily') }} b
    left join att_budget ab on b.report_date = ab.report_date
    left join {{ ref('dim_facility') }} df on b.key_facility = df.key_facility
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
    from act where facility_group = '{{ a.fg }}'
      {% endfor %}
      {# ratios: carry numerator/denominator, not a pre-divided value #}
      {% for suffix, num, den in a.ratios %}
    union all
    select report_date, key_facility,
           '{{ a.prefix }}__{{ suffix }}' as line_item_code,
           cast(null as number(38,4)) as amount,
           cast({{ num }} as number(38,4)) as numerator,
           cast({{ den }} as number(38,4)) as denominator
    from act where facility_group = '{{ a.fg }}'
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
    from bud where facility_group = '{{ a.fg }}'
      {% endfor %}
      {% for suffix, num, den in a.ratios %}
    union all
    select report_date, key_facility,
           '{{ a.prefix }}__{{ suffix }}' as line_item_code,
           cast(null as number(38,4)) as budget_amount,
           cast({{ num }} as number(38,4)) as budget_numerator,
           cast({{ den }} as number(38,4)) as budget_denominator
    from bud where facility_group = '{{ a.fg }}'
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
