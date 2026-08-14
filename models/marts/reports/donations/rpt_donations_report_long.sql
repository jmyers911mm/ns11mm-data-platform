-- Marts report: long/unpivoted Donations Analysis serving shape (one row per line item)
-- ---------------------------------------------------------------------------
-- Domain: donations
-- Grain:  one row per report_date x line_item_code
--
-- Tidy Donations Analysis Report presentation: unpivots fct_donations into one
-- long shape covering all 36 printed lines across 12 sections, with the
-- report's six non-additive per-visitor ratios resolved as numerator /
-- denominator components rather than stored quotients. Sibling of
-- rpt_retail_report_long and rpt_attendance_report_long. Feeds the Power BI
-- Donations Analysis matrix, which joins dim_donations_line_item for
-- section/label/order/format/availability and dim_date for period columns
-- (the legacy workbook is one sheet per calendar year, so the Power BI slicer
-- replaces the sheet tabs).
--
-- Legacy lineage: t_donations_analysis_tabs (the printed column list),
-- t_fact_donations_analysis_report, fact_all_donations.
--
-- NO BUDGET SIDE. The legacy Donations Analysis Report prints actuals only --
-- there is no goal column on any of its sheets. fct_budget_dpr_forecasts does
-- carry donations_ticketing / museum_exit_donations / per-facility donation
-- goals, but those are the DPR's budget lines and wiring them in here would
-- invent a comparison the report has never shown. budget_* columns are
-- therefore omitted entirely rather than carried NULL (same choice as
-- rpt_attendance_report_long).
--
-- RATIO RULE (ADR-021). Ratio rows carry numerator and denominator and leave
-- `amount` NULL; additive rows carry `amount` and leave both components NULL.
-- Power BI divides SUM(numerator) / SUM(denominator) at whatever grain the user
-- lands on, so a monthly or yearly per-visitor figure is a ratio-of-sums, never
-- an average of daily ratios. The legacy table stored all six pre-divided; none
-- of those columns is reproduced anywhere in this stack.
--
-- LEG_* lines (section 12) are the seven fact_all_donations columns that
-- finance_mtd_dpr.prpt and finance_ytd_dpr.prpt bind to. They are roll-ups of
-- the component lines above them, so section 12 must NOT be summed together
-- with sections 1-11, and the seven legs must not be summed with each other
-- either -- LEG_KIOSK_COATCHECK and LEG_MUS_EXIT both contain the box-office
-- exit box (legacy's own overlap; see fct_donations and NOTES.md finding 3).
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

{#- Additive lines: line_item_code -> expression on fct_donations. -#}
{% set additive_lines = [
    ('MEM_ATTENDANCE',          'mem_attendance'),
    ('MUS_ATTENDANCE',          'mus_attendance'),
    ('MEM_ONLY_VISITORS',       'mem_only_visitors'),
    ('TICKETING_DONATIONS',     'ticketing_donations'),
    ('MUS_STORE_VISITORS',      'mus_store_visitors'),
    ('MUS_STORE_DON',           'mus_store_don'),
    ('VESEY_VISITORS',          'vesey_visitors'),
    ('VESEY_DONATIONS',         'vesey_donations'),
    ('RETAIL_CART_DON',         'retail_cart_don'),
    ('VS_CART_DON',             'vs_cart_don'),
    ('TOTAL_CART_DON',          'retail_cart_don + vs_cart_don'),
    ('CAFE_DONATIONS',          'cafe_donations'),
    ('CAFE1_DONATIONS',         'cafe1_donations'),
    ('COATCHECK_DON',           'coatcheck_don'),
    ('MUS_EXIT_DON',            'mus_exit_don'),
    ('BOX_OFFICE_MEM_DON',      'box_office_mem_don'),
    ('BOX_OFFICE_MUS_EXIT_DON', 'box_office_mus_exit_don'),
    ('MEM_CART_ASK_DON',        'mem_cart_ask_don'),
    ('MUS_PLAZA_BOX_DON',       'mus_plaza_box_don'),
    ('MEM_CART_OTHER_DON',      'mem_cart_other_don'),
    ('MEMORIAL_KIOSK_DON',      'memorial_kiosk_don'),
    ('SHOPIFY_DON',             'shopify_don'),
    ('MASK_DON',                'mask_don'),
    ('LEG_TICKETING',           'ticketing_donations'),
    ('LEG_KIOSK_COATCHECK',     'kiosk_coatcheck_donations'),
    ('LEG_MUS_EXIT',            'mus_exit_leg_donations'),
    ('LEG_MUS_STORE',           'mus_store_don'),
    ('LEG_RETAIL_CART',         'retail_cart_don'),
    ('LEG_SHOPIFY',             'shopify_don'),
    ('LEG_CAFE',                'cafe_donations')
] %}

{#- Ratio lines: line_item_code -> (numerator expression, denominator expr).  -#}
{#- These are the six quotients legacy stored in fact_donations_analysis_     -#}
{#- report. Carried as components only.                                       -#}
{% set ratio_lines = [
    ('MS_DON_PER_STORE_VISITOR',      'mus_store_don',                  'mus_store_visitors'),
    ('MS_DON_PER_MUS_VISITOR',        'mus_store_don',                  'mus_attendance'),
    ('VESEY_DON_PER_VESEY_VISITOR',   'vesey_donations',                'vesey_visitors'),
    ('CART_DON_PER_MEM_ONLY_VISITOR', 'retail_cart_don + vs_cart_don',  'mem_only_visitors'),
    ('COATCHECK_DON_PER_MUS_VISITOR', 'coatcheck_don',                  'mus_attendance'),
    ('MUS_EXIT_DON_PER_MUS_VISITOR',  'mus_exit_don',                   'mus_attendance')
] %}

with f as (
    select * from {{ ref('fct_donations') }}
),

long as (
    {% for code, col in additive_lines %}
    select
        date_value                                  as report_date,
        is_commemoration_day,
        '{{ code }}'                                as line_item_code,
        cast({{ col }} as number(38,4))             as amount,
        cast(null as number(38,4))                  as numerator,
        cast(null as number(38,4))                  as denominator
    from f
    union all
    {% endfor %}

    {% for code, num, den in ratio_lines %}
    select
        date_value                                  as report_date,
        is_commemoration_day,
        '{{ code }}'                                as line_item_code,
        cast(null as number(38,4))                  as amount,
        cast({{ num }} as number(38,4))             as numerator,
        cast({{ den }} as number(38,4))             as denominator
    from f
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
)

select
    report_date,
    is_commemoration_day,
    line_item_code,
    amount,
    numerator,
    denominator
from long
