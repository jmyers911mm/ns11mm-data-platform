-- Marts report: budget-vs-actual daily serving — day-grain DPR budget
-- ---------------------------------------------------------------------------
-- Domain: DPR / budget
-- Grain:  one row per report_date
--
-- Day-grain BUDGET for the DPR, conformed from the three budget facts:
-- fct_budget_dpr_forecasts (primary), fct_budget_admissions_forecasts
-- (attendance + guided tours, facility-summed), and
-- fct_budget_retail_forecasts (store / carts / cafe profit by selling area).
-- Column names are aligned to rpt_dpr_powerbi (the actuals) so the two
-- unpivot identically. Feeds rpt_dpr_report_long and rpt_dpr_narrative_brief.
-- NOTE: intentionally NOT populated (left blank on budget, per decision):
-- the two donation composites, Professional Program Revenue, Total Estimated
-- Revenue (depends on the unmapped donations), and Virtual Tour Revenue.
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view') }}

with dpr as (
    select
        date_value                     as report_date,
        tickets_sold                   as tickets_sold,
        ticket_revenue                 as ticket_revenue,
        pass_revenue                   as pass_revenue,
        total_admission_revenue        as admission_revenue,
        early_access_tours             as early_access_tour_count,   -- budget fills an actuals gap
        early_access_tour_rev          as revealed_tour_revenue,
        audio_tour_headsets            as audio_tour_headset,
        profit_from_ecom               as ecom_gross_profit,         -- budget fills an actuals gap
        youth_fam_tour_rev             as virtual_yf_tour_revenue
    from {{ ref('fct_budget_dpr_forecasts') }}
),

adm as (
    select
        date_value                     as report_date,
        sum(mem_attendance)            as memorial_attendance,
        sum(mus_attendance)            as museum_attendance,
        sum(mem_mus_tours)             as mem_mus_tours,
        sum(mem_mus_tour_revenue)      as mem_mus_tour_revenue,
        sum(mus_guided_tours)          as museum_guided_tours,
        sum(mus_guided_tour_revenue)   as mus_guided_tour_revenue,
        sum(mem_guided_tours)          as memorial_guided_tours,
        sum(mem_guided_tour_revenue)   as mem_guided_tour_revenue
    from {{ ref('fct_budget_admissions_forecasts') }}
    group by 1
),

ret as (
    -- Selling areas resolved via dim_facility.facility_group (conformed name),
    -- not raw key_facility numbers.
    select
        f.date_value                                                                   as report_date,
        sum(case when df.facility_group = 'museum_store'   then f.profit_from_retail end) as mus_store_gross_profit,
        sum(case when df.facility_group = 'memorial_carts' then f.profit_from_retail end) as retail_carts_gross_profit,
        sum(case when df.facility_group = 'museum_cafe'    then f.profit_from_retail end) as cafe_profit
    from {{ ref('fct_budget_retail_forecasts') }} f
    left join {{ ref('dim_facility') }} df on f.key_facility = df.key_facility
    group by 1
),

spine as (
    select report_date from dpr
    union
    select report_date from adm
    union
    select report_date from ret
)

select
    s.report_date,
    -- attendance (Admissions)
    adm.memorial_attendance,
    adm.museum_attendance,
    -- admissions (DPR)
    dpr.tickets_sold,
    dpr.ticket_revenue,
    dpr.pass_revenue,
    dpr.admission_revenue,
    -- tours (DPR early access + Admissions guided)
    dpr.early_access_tour_count,
    dpr.revealed_tour_revenue,
    adm.mem_mus_tours,
    adm.mem_mus_tour_revenue,
    adm.museum_guided_tours,
    adm.mus_guided_tour_revenue,
    adm.memorial_guided_tours,
    adm.mem_guided_tour_revenue,
    -- retail & cafe (Retail facilities + DPR ecom)
    ret.mus_store_gross_profit,
    ret.retail_carts_gross_profit,
    dpr.ecom_gross_profit,
    ret.cafe_profit,
    -- other (DPR)
    dpr.audio_tour_headset,
    dpr.virtual_yf_tour_revenue
from spine s
left join dpr on s.report_date = dpr.report_date
left join adm on s.report_date = adm.report_date
left join ret on s.report_date = ret.report_date