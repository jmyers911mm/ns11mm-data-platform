-- Test (reconciliation): Retail Analysis sales never exceed the unexcluded retail sales for the same facility-day
-- Severity: error — fct_retail_analysis.sales_amount is fct_retail_daily.net_sales
-- MINUS the legacy excluded items, over the same lines and the same netting
-- convention. It can be lower (an excluded item sold that day) and it can be
-- equal (none did). It can never be HIGHER. A higher value means one of three
-- real defects: the exclusion join fanned out and double-counted lines, the two
-- models drifted onto different facility scopes, or the netting convention
-- diverged between int_retail__analysis and int_retail__performance.
--
-- This is the guard on the one seam 8.10.0 creates: two models that both
-- compute "retail sales" for the same facility-day and are DELIBERATELY not
-- equal. Anything that makes them equal-by-accident, or inverts the
-- inequality, is a defect in one of them.
--
-- Tolerance is 0.01 to absorb NUMBER(38,4) rounding, not to absorb logic.

with analysis as (
    select
        date_key,
        key_facility,
        sales_amount,
        units_sold
    from {{ ref('fct_retail_analysis') }}
),

daily as (
    select
        date_key,
        key_facility,
        net_sales,
        net_units
    from {{ ref('fct_retail_daily') }}
),

compared as (
    select
        a.date_key,
        a.key_facility,
        a.sales_amount,
        d.net_sales,
        a.sales_amount - d.net_sales    as sales_excess,
        a.units_sold,
        d.net_units,
        a.units_sold - d.net_units      as units_excess
    from analysis a
    inner join daily d
        on a.date_key = d.date_key
       and a.key_facility = d.key_facility
)

select
    'analysis_sales_exceed_unexcluded_sales' as failure,
    date_key,
    key_facility,
    sales_amount,
    net_sales,
    sales_excess     as excess
from compared
where sales_excess > 0.01

union all

select
    'analysis_units_exceed_unexcluded_units' as failure,
    date_key,
    key_facility,
    units_sold       as sales_amount,
    net_units        as net_sales,
    units_excess     as excess
from compared
where units_excess > 0.01
