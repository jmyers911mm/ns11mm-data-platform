-- Silver intermediate: guided-tour, virtual-tour, field-trip, and program revenue
-- ---------------------------------------------------------------------------
-- Domain: admissions / tours
-- Grain: one row per date_key
--
-- Recreates the DPR tour-family line items from the enriched Gateway ticket
-- journal. Each measure is (quantity, revenue) for a product cohort selected
-- by matrix code and/or PLU, all with ga_flag = 0 (tour, not general admission).
--
-- PLU-enumerable cohorts (field trips, revealed, ask-educator, and the set of
-- PLUs excluded from core museum guided tours) are seed-driven via
-- seed_tour_plu -- edit that seed to add/retire a PLU, no model change needed.
-- Matrix-code cohorts (%TOU%, %MGT%, %VTM%, %VTU%, %VTF%) stay inline because
-- they are pattern matches over an open set of PLUs, not an enumerable list.
--
-- Legacy lineage: t_reporting_mus_guided_tours_revenue,
-- t_reporting_mem_guided_tours_revenue, t_reporting_virtual_*_revenue,
-- t_reporting_mus_field_trip_revenue, t_reporting_mem_field_trip_revenue,
-- t_reporting_revealed_tour_revenue, t_reporting_ask_educator,
-- t_reporting_youth_fam_tours_revenue, t_reporting_ea_mem_mus_tour_revenue.
--
-- 8.1.0 DOUBLE-COUNT FIX (revealed tour inside the virtual-memorial cohort):
-- revealed_tour_revenue and virtual_mem_tour_revenue were both drawn from the
-- SAME rows. Legacy separates them on PLU inside the one %VTM% matrix cohort:
--   t_reporting_revealed_tour_revenue  -> account_idno like '%VTM%'
--                                         AND g.plu = 'VTMUSOBLOADW001'
--   t_reporting_virtual_mem_tours_revenue -> account_idno like '%VTM%'
--                                         AND key_museum_category NOT IN (...)
-- (the excluded category list is the revealed/buyout carve-out expressed as
-- 911dw category keys). dbt had the revealed carve-out on the seed side only,
-- so VTMUSOBLOADW001 was counted once as revealed_tour_revenue and again as
-- virtual_mem_tour_revenue -- and rpt_dpr_report_long adds BOTH into
-- TOTAL_TOUR_REVENUE (revealed_tour_revenue + ... + virtual_tour_revenue),
-- so the revealed dollars landed in that total twice. The virtual-memorial
-- cohort now excludes the seed-labelled revealed PLU.
--
-- NOTE: buyout components (fact_museum_guided_tour_buyout) and the
-- issued/unissued split of the ORIGINAL Pentaho flow are consolidated here
-- into recognized-line revenue. Confirm buyout handling with Chris Wogas
-- before go-live (flagged in build notes). Early-access (ea_mem_mus) tour
-- revenue is buyout-derived and remains gated on that decision.

{{ config(materialized='view') }}

with lines as (
    select * from {{ ref('int_gateway__ticket_journal_lines') }}
    where ga_flag = 0
),

tour_plu as (
    select plu, dpr_line_item
    from {{ ref('seed_tour_plu') }}
),

-- Any PLU present in the seed is NOT a core museum/memorial guided tour (it is
-- a field trip, revealed, architecture, ask-educator, etc.). This replaces the
-- former hardcoded exclusion list.
labeled as (
    select
        l.*,
        tp.dpr_line_item                                                   as plu_line_item
    from lines l
    left join tour_plu tp on l.plu = tp.plu
),

aggregated as (
    select
        date_key,

        -- Museum guided tours: TOU matrix, excluding any seed-listed PLU
        sum(case when matrix_code like '%TOU%' and plu_line_item is null
                 then quantity else 0 end)                                 as mus_guided_tours,
        sum(case when matrix_code like '%TOU%' and plu_line_item is null
                 then amount else 0 end)                                   as mus_guided_tour_revenue,

        -- Memorial guided tours: MGT matrix, excluding any seed-listed PLU.
        -- Distinct from mem_mus_tour (%MTG%, combined) and from field trips
        -- (seed-labeled), so no double-count. Legacy: t_reporting_mem_guided_tours_revenue.
        sum(case when matrix_code like '%MGT%' and plu_line_item is null
                 then quantity else 0 end)                                 as mem_guided_tours,
        sum(case when matrix_code like '%MGT%' and plu_line_item is null
                 then amount else 0 end)                                   as mem_guided_tour_revenue,

        -- Memorial field trips (seed-labeled)
        sum(case when plu_line_item = 'mem_field_trip' then quantity else 0 end)
                                                                           as mem_field_trips,
        sum(case when plu_line_item = 'mem_field_trip' then amount else 0 end)
                                                                           as mem_field_trip_revenue,

        -- Museum field trips (seed-labeled)
        sum(case when plu_line_item = 'mus_field_trip' then quantity else 0 end)
                                                                           as mus_field_trips,
        sum(case when plu_line_item = 'mus_field_trip' then amount else 0 end)
                                                                           as mus_field_trip_revenue,

        -- Revealed tour (seed-labeled)
        sum(case when plu_line_item = 'revealed_tour' then amount else 0 end)
                                                                           as revealed_tour_revenue,

        -- Ask an Educator (seed-labeled)
        sum(case when plu_line_item = 'ask_educator' then amount else 0 end)
                                                                           as ask_educator_revenue,

        -- Virtual Memorial Tour (matrix pattern), less the revealed-tour PLU.
        -- The revealed tour (VTMUSOBLOADW001) carries a %VTM% matrix code but
        -- is reported on its own line; without this carve-out it is counted in
        -- both revealed_tour_revenue and virtual_mem_tour_revenue.
        sum(case when matrix_code like '%VTM%'
                  and coalesce(plu_line_item, '') <> 'revealed_tour'
                 then quantity else 0 end)                                 as virtual_mem_tours,
        sum(case when matrix_code like '%VTM%'
                  and coalesce(plu_line_item, '') <> 'revealed_tour'
                 then amount else 0 end)                                   as virtual_mem_tour_revenue,

        -- Virtual Museum Tour (matrix pattern)
        sum(case when matrix_code like '%VTU%' then quantity else 0 end)   as virtual_mus_tours,
        sum(case when matrix_code like '%VTU%' then amount else 0 end)     as virtual_mus_tour_revenue,

        -- Virtual Youth & Family Memorial Tour (matrix pattern)
        sum(case when matrix_code like '%VTF%' then quantity else 0 end)   as virtual_yf_mem_tours,
        sum(case when matrix_code like '%VTF%' then amount else 0 end)     as virtual_yf_mem_tour_revenue

    from labeled
    group by date_key
)

select * from aggregated
