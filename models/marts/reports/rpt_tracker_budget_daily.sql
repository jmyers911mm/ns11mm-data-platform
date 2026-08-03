-- Marts report: budget-vs-actual daily serving — day-grain Tracker projection
-- ---------------------------------------------------------------------------
-- Domain: DPR / budget
-- Grain:  one row per report_date
--
-- Day-grain PROJECTION for the Memorial & Museum Daily Tracker (YTD), a thin
-- projection of rpt_dpr_budget_daily. Column names mirror rpt_tracker_powerbi
-- (the actuals) so the two unpivot IDENTICALLY in rpt_tracker_report_long —
-- same trick as rpt_retail_budget_daily. Feeds rpt_tracker_report_long (the
-- "... Projection" rows) and rpt_tracker_narrative_brief.
-- NOTE (documented assumption, confirm vs the legacy projection): donations
-- and virtual-tour revenue are NOT in the budget, so they are excluded from
-- the Earned Revenue Projection — the donation columns and
-- virtual_tour_revenue are emitted as typed NULL to keep the column set
-- aligned with the actuals.
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view') }}

select
    report_date,

    -- attendance & tickets
    memorial_attendance,
    museum_attendance,
    tickets_sold,

    -- admissions
    admission_revenue,

    -- tours (virtual has no budget source -> typed NULL)
    revealed_tour_revenue,
    mem_mus_tour_revenue,
    mus_guided_tour_revenue,
    mem_guided_tour_revenue,
    cast(null as number(38,4))     as virtual_tour_revenue,

    -- retail & cafe
    mus_store_gross_profit,
    retail_carts_gross_profit,
    cafe_profit,

    -- audio
    audio_tour_headset,

    -- donation components: not in the budget -> typed NULL (excluded from the projection)
    cast(null as number(38,4))     as cart_donation_ask,
    cast(null as number(38,4))     as box_office_mem_don,
    cast(null as number(38,4))     as donation_box,
    cast(null as number(38,4))     as ecom_donation_ask,
    cast(null as number(38,4))     as ticketing_donations,
    cast(null as number(38,4))     as box_office_mus_exit_don,
    cast(null as number(38,4))     as coatcheck_don,
    cast(null as number(38,4))     as mus_store_don,
    cast(null as number(38,4))     as mus_exit_don,
    cast(null as number(38,4))     as cafe_don
from {{ ref('rpt_dpr_budget_daily') }}
