-- Marts fact: retail analysis (facility-day)
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain: one row per date_key x key_facility
--
-- The platform's replacement for legacy 911dw.fact_retail_analysis. Load-
-- bearing independently of its own report: five already-migrated live surfaces
-- read the legacy table today -- Retail Performance
-- (911dw.dayofdata.arialnormal), DPR-MTD (finance_mtd_dpr), DPR-YTD
-- (finance_ytd_dpr), Tracker-YTD (memorial_museum_daily_tracker_ytd) and the
-- Carts Analysis workbook (t_retail_cart_analysis_tabs) -- plus the DPR's
-- audio_tour_headset roll-up, which folds mag_profit / musag_profit in through
-- t_reporting_memorial_audio_headset_revenue and
-- t_reporting_museum_audio_headset_revenue.
--
-- GRAIN CHOICE. Legacy is one row per key_date with the facility encoded in
-- ~40 column NAMES (mus_store_*, vesey_*, mem_cart_*, cafe1_*, mag_*, musag_*,
-- mgt_*, mus_memberships_*, ecom_*). Every consumer reads it as
-- SUM(<area>_<measure>) over a date range, so a facility-day fact plus a
-- facility_group predicate returns the identical number without hardcoding the
-- facility vocabulary into column names, and matches the grain of its sibling
-- fct_retail_daily. The mapping is one-for-one:
--   mus_store_visitors  -> visitors            where facility_group='museum_store'
--   mus_store_customers -> customers           where facility_group='museum_store'
--   sales_mus_store     -> sales_amount        where facility_group='museum_store'
--   cost_mus_store      -> cost_amount         where facility_group='museum_store'
--   profit_mus_store    -> gross_profit        where facility_group='museum_store'
--   vesey_*             -> same, facility_group='preview_vesey'
--   mem_cart_* / sales_mem_cart / cost_mem_cart -> facility_group='memorial_carts'
--   cafe1_sales_all / cafe1_customers / cafe1_profit_all -> 'museum_cafe'
--   mag_* / musag_* / mgt_* / mus_memberships_* -> 'mag_cart' / 'mus_ag' /
--       key_facility 1070 / key_facility 1080
--   ecom_orders / ecom_sales / ecom_profit -> facility_group='ecommerce'
--   mus_visitors -> museum_attendance, mem_attendance -> memorial_attendance
--       (day-level, repeated on every facility row -- do NOT sum across
--        facilities; take MAX or filter to one facility)
--
-- Additive components only. Every legacy ratio column (ms_capture_rate,
-- ms_conversion_rate, mus_store_avg_sale, mus_store_profit_per_cust,
-- vesey_conversion_rate, vesey_avg_sale, profit_per_cust_vesey, ecom_avg_sale,
-- ecom_profit_per_order, mem_cart_capture_rate, mem_cart_avg_sale,
-- mem_cart_profit_per_cust) is deliberately absent: the pair is carried and the
-- division happens once at display grain (ADR-021 ratio rule). The legacy
-- *_diff columns are likewise absent -- variance is actual minus budget at the
-- display grain, resolved in rpt_retail_analysis_report_long.
--
-- Legacy lineage: 911dw.fact_retail_analysis (t_fact_mus_store_analysis).
-- STATUS: water_* and medallion_* are typed NULLs with their causes stated on
-- int_retail__analysis; the layout seed marks their five lines Stub.
-- SCOPE NOTE: ADR-005. sales_amount / units_sold apply the legacy membership
-- item exclusion (seed_retail_analysis_excluded_item) and therefore do NOT
-- equal fct_retail_daily.net_sales / net_units at the same facility-day. Both
-- are correct for their own certified series; substituting one for the other is
-- a defect. Owner: Gennady Zaritsky.
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='table', cluster_by=['date_key']) }}

with analysis as (
    select * from {{ ref('int_retail__analysis') }}
),

facility as (
    select * from {{ ref('dim_facility') }}
),

final as (
    select
        dd.date_key,
        a.date_key                                              as date_value,
        a.key_facility,
        coalesce(f.area_name, 'Unmapped ' || a.key_facility)    as area_name,
        f.area_group,
        coalesce(f.facility_group, 'other')                     as facility_group,
        dd.is_commemoration_day,

        -- Counts
        a.visitors,
        a.customers,

        -- Day-level attendance denominators (repeated per facility row)
        a.museum_attendance,
        a.memorial_attendance,

        -- Money
        a.sales_amount,
        a.cost_amount,
        a.gross_profit,
        a.units_sold,

        -- Carve-outs (typed NULL where unbuildable -- see header)
        a.water_sales,
        a.water_cost,
        a.water_gross_profit,
        a.medallion_sales,
        a.medallion_profit,
        a.medallion_units_sold

    from analysis a
    inner join {{ ref('dim_date') }} dd
        on a.date_key = dd.date_key
    left join facility f
        on a.key_facility = f.key_facility
)

select * from final
