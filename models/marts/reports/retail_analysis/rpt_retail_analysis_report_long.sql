-- Marts report: long/unpivoted Retail Analysis serving shape (actual + budget per line item)
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per report_date x key_facility x line_item_code
--
-- Tidy Retail Analysis presentation: unpivots fct_retail_analysis (actual) and
-- the retail + DPR budget facts (goal) into one long shape carrying BOTH
-- scenarios, with every non-additive measure resolved as numerator/denominator
-- components in SQL. Sibling of rpt_retail_report_long. Feeds the Power BI
-- Retail Analysis matrix, which joins dim_retail_analysis_line_item for
-- section/label/order/format and dim_date for the year axis.
--
-- THE YEAR AXIS IS NOT A LAYOUT AXIS. The legacy workbook is thirteen Excel
-- sheets driven by a single query with `year(key_date) as year` as the routing
-- field (t_retail_analysis_tabs.sql:24; the same transformation had 5 sheets in
-- _test and 9 in _bk as the years accumulated). The sheets are calendar years
-- 2014-2026, not report sections, so they are a dim_date slicer here and the
-- layout seed's sections are the four printed measure blocks.
--
-- NOTE: ratio rows carry numerator/denominator and never a pre-divided value,
-- so Power BI recomputes ratio-of-sums at any grain (ADR-021 ratio rule). The
-- legacy *_diff columns are not stored: variance is actual minus budget at the
-- display grain. That is a deliberate behavioural difference on the four
-- ratio variances -- legacy subtracts two DAY-grain pre-divided ratios, this
-- model subtracts two ratio-of-sums, and the two disagree at any grain coarser
-- than a day. Legacy's form is an average-of-ratios artefact; ours is the one
-- ADR-021 requires.
--
-- NOTE: no *_powerbi wrapper. ADR-021 makes the wrapper the only caller of
-- SEMANTIC_VIEW(), and 8.10.0 adds no RETAIL_ANALYSIS semantic view, so this
-- shape reads the mart fact directly -- the same path rpt_carts_report_long
-- takes. Adding the semantic view is the follow-up that would insert a wrapper
-- between them; nothing here reads rightward.
--
-- Legacy lineage: t_retail_analysis_tabs (the 13 sheets), over
-- 911dw.fact_retail_analysis / fact_retail_forecasts / fact_dpr_forecasts.
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

{#- ------------------------------------------------------------------ -#}
{#- Area map. Areas are selected by dim_facility.facility_group (the     -#}
{#- conformed name), never by raw key_facility numbers. Actual and       -#}
{#- budget legs expose IDENTICAL column names so one expression serves   -#}
{#- both sides; a measure with no budget source is NULL on the budget    -#}
{#- leg, never zero.                                                     -#}
{% set areas = [
  {'prefix':'MS',       'fg':'museum_store',
     'additive':[('VISITORS','visitors'),('CUSTOMERS','customers'),('SALES','sales_amount'),('COST','cost_amount'),('PROFIT','gross_profit')],
     'ratios':[('CAPTURE_RATE','visitors','museum_attendance'),
               ('CONVERSION_RATE','customers','visitors'),
               ('AVG_SALE','sales_amount','customers'),
               ('PROFIT_PER_CUST','gross_profit','customers')] },
  {'prefix':'VESEY',    'fg':'preview_vesey',
     'additive':[('VISITORS','visitors'),('CUSTOMERS','customers'),('PROFIT','gross_profit')],
     'ratios':[('CONVERSION_RATE','customers','visitors'),
               ('AVG_SALE','sales_amount','customers'),
               ('PROFIT_PER_CUST','gross_profit','customers')] },
  {'prefix':'ECOM',     'fg':'ecommerce',
     'additive':[('ORDERS','customers'),('SALES','sales_amount'),('PROFIT','gross_profit')],
     'ratios':[('AVG_SALE','sales_amount','customers'),
               ('PROFIT_PER_ORDER','gross_profit','customers')] },
  {'prefix':'MEM_CART', 'fg':'memorial_carts',
     'additive':[('MEMORIAL_ATTENDANCE','memorial_attendance'),('CUSTOMERS','customers'),('PROFIT','gross_profit')],
     'ratios':[('CAPTURE_RATE','customers','memorial_attendance'),
               ('AVG_SALE','sales_amount','customers'),
               ('PROFIT_PER_CUST','gross_profit','customers')] }
] %}

{#- Carve-out lines that do not follow the PREFIX__SUFFIX area pattern.  -#}
{#- All five are typed NULL today and marked Stub in the layout seed;    -#}
{#- they are emitted rather than omitted so the gap is visible on the    -#}
{#- report surface (ADR-021 placeholder rule).                           -#}
{% set extras = [
  ('WATER__MUS_STORE',      'museum_store',   'water_gross_profit'),
  ('WATER__MEM_CART',       'memorial_carts', 'water_gross_profit'),
  ('MEDALLION__SALES',      'museum_cafe',    'medallion_sales'),
  ('MEDALLION__PROFIT',     'museum_cafe',    'medallion_profit'),
  ('MEDALLION__UNITS_SOLD', 'museum_cafe',    'medallion_units_sold')
] %}

{% set ecom_key_facility = 1234 %}   {# Ecommerce facility (see seed_facility_area) #}

with
-- =========================================================== ACTUAL
act as (
    select
        date_value                          as report_date,
        key_facility,
        facility_group,
        visitors,
        customers,
        sales_amount,
        cost_amount,
        gross_profit,
        museum_attendance,
        memorial_attendance,
        water_gross_profit,
        medallion_sales,
        medallion_profit,
        medallion_units_sold
    from {{ ref('fct_retail_analysis') }}
),

-- =========================================================== BUDGET
-- Two legs, exactly as legacy has two: the per-facility retail forecast
-- (t_fact_mus_store_analysis Table input 3, over fact_retail_forecasts) and the
-- day-grain ecommerce forecast (Table input 5, over fact_dpr_forecasts). The
-- retail leg excludes 1234 so the two legs cannot both claim ecommerce.
bud_facility as (
    select
        b.report_date,
        b.key_facility,
        coalesce(df.facility_group, 'other')     as facility_group,
        b.visitor_count                          as visitors,
        b.transactions                           as customers,
        b.net_sales                              as sales_amount,
        cast(null as number(38, 4))              as cost_amount,          -- no budget source
        b.net_profit                             as gross_profit,
        b.museum_attendance                      as museum_attendance,
        cast(null as number(38, 4))              as memorial_attendance,  -- no budget source
        cast(null as number(38, 4))              as water_gross_profit,   -- no budget source
        cast(null as number(38, 4))              as medallion_sales,      -- no budget source
        cast(null as number(38, 4))              as medallion_profit,     -- no budget source
        cast(null as number(38, 4))              as medallion_units_sold  -- no budget source
    from {{ ref('rpt_retail_budget_daily') }} b
    left join {{ ref('dim_facility') }} df
        on b.key_facility = df.key_facility
    where b.key_facility <> {{ ecom_key_facility }}
),

bud_ecom as (
    select
        e.date_value                             as report_date,
        {{ ecom_key_facility }}                  as key_facility,
        'ecommerce'                              as facility_group,
        cast(null as number(38, 4))              as visitors,             -- no budget source
        e.ecom_orders                            as customers,
        e.total_sales_ecom                       as sales_amount,
        cast(null as number(38, 4))              as cost_amount,
        e.profit_from_ecom                       as gross_profit,
        cast(null as number(38, 4))              as museum_attendance,
        cast(null as number(38, 4))              as memorial_attendance,
        cast(null as number(38, 4))              as water_gross_profit,
        cast(null as number(38, 4))              as medallion_sales,
        cast(null as number(38, 4))              as medallion_profit,
        cast(null as number(38, 4))              as medallion_units_sold
    from {{ ref('fct_budget_dpr_forecasts') }} e
),

bud as (
    select * from bud_facility
    union all
    select * from bud_ecom
),

-- Day-level attendance line. museum_attendance is repeated on every facility
-- row of the fact, so this is MAX per day, never SUM.
att_actual as (
    select report_date, max(museum_attendance) as museum_attendance
    from act group by 1
),
att_budget as (
    select report_date, max(museum_attendance) as museum_attendance
    from bud group by 1
),

-- =========================================================== ACTUAL long
actual_long as (
    select
        report_date,
        cast(null as number)                        as key_facility,
        'MUSEUM_ATTENDANCE'                         as line_item_code,
        cast(museum_attendance as number(38, 4))    as amount,
        cast(null as number(38, 4))                 as numerator,
        cast(null as number(38, 4))                 as denominator
    from att_actual

    {% for a in areas %}
      {% for suffix, col in a.additive %}
    union all
    select
        report_date,
        key_facility,
        '{{ a.prefix }}__{{ suffix }}'              as line_item_code,
        cast({{ col }} as number(38, 4))            as amount,
        cast(null as number(38, 4)),
        cast(null as number(38, 4))
    from act where facility_group = '{{ a.fg }}'
      {% endfor %}
      {% for suffix, num, den in a.ratios %}
    union all
    select
        report_date,
        key_facility,
        '{{ a.prefix }}__{{ suffix }}'              as line_item_code,
        cast(null as number(38, 4))                 as amount,
        cast({{ num }} as number(38, 4))            as numerator,
        cast({{ den }} as number(38, 4))            as denominator
    from act where facility_group = '{{ a.fg }}'
      {% endfor %}
    {% endfor %}

    {% for code, fg, col in extras %}
    union all
    select
        report_date,
        key_facility,
        '{{ code }}'                                as line_item_code,
        cast({{ col }} as number(38, 4))            as amount,
        cast(null as number(38, 4)),
        cast(null as number(38, 4))
    from act where facility_group = '{{ fg }}'
    {% endfor %}
),

-- =========================================================== BUDGET long
budget_long as (
    select
        report_date,
        cast(null as number)                        as key_facility,
        'MUSEUM_ATTENDANCE'                         as line_item_code,
        cast(museum_attendance as number(38, 4))    as budget_amount,
        cast(null as number(38, 4))                 as budget_numerator,
        cast(null as number(38, 4))                 as budget_denominator
    from att_budget

    {% for a in areas %}
      {% for suffix, col in a.additive %}
    union all
    select
        report_date,
        key_facility,
        '{{ a.prefix }}__{{ suffix }}'              as line_item_code,
        cast({{ col }} as number(38, 4))            as budget_amount,
        cast(null as number(38, 4)),
        cast(null as number(38, 4))
    from bud where facility_group = '{{ a.fg }}'
      {% endfor %}
      {% for suffix, num, den in a.ratios %}
    union all
    select
        report_date,
        key_facility,
        '{{ a.prefix }}__{{ suffix }}'              as line_item_code,
        cast(null as number(38, 4))                 as budget_amount,
        cast({{ num }} as number(38, 4))            as budget_numerator,
        cast({{ den }} as number(38, 4))            as budget_denominator
    from bud where facility_group = '{{ a.fg }}'
      {% endfor %}
    {% endfor %}

    {% for code, fg, col in extras %}
    union all
    select
        report_date,
        key_facility,
        '{{ code }}'                                as line_item_code,
        cast({{ col }} as number(38, 4))            as budget_amount,
        cast(null as number(38, 4)),
        cast(null as number(38, 4))
    from bud where facility_group = '{{ fg }}'
    {% endfor %}
)

-- =========================================================== MERGE
select
    coalesce(a.report_date, b.report_date)          as report_date,
    coalesce(a.key_facility, b.key_facility)        as key_facility,
    coalesce(a.line_item_code, b.line_item_code)    as line_item_code,
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
