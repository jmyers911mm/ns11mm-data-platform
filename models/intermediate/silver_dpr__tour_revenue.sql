-- Silver DPR: guided-tour, virtual-tour, field-trip, and program revenue
-- ---------------------------------------------------------------------------
-- Domain: admissions / tours
-- Grain:  one row per key_date
--
-- Recreates the DPR tour-family line items from the enriched Gateway ticket
-- journal. Each measure is (quantity, revenue) for a product cohort selected
-- by matrix code and/or PLU, all with ga_flag = 0 (tour, not general admission).
--
-- PLU-enumerable cohorts (field trips, revealed, ask-educator, and the set of
-- PLUs excluded from core museum guided tours) are seed-driven via
-- seed_tour_plu -- edit that seed to add/retire a PLU, no model change needed.
-- Matrix-code cohorts (%TOU%, %VTM%, %VTU%, %VTF%) stay inline because they are
-- pattern matches over an open set of PLUs, not an enumerable list.
--
-- Legacy lineage: t_reporting_mus_guided_tours_revenue,
-- t_reporting_mem_guided_tours_revenue, t_reporting_virtual_*_revenue,
-- t_reporting_mus_field_trip_revenue, t_reporting_mem_field_trip_revenue,
-- t_reporting_revealed_tour_revenue, t_reporting_ask_educator,
-- t_reporting_youth_fam_tours_revenue, t_reporting_ea_mem_mus_tour_revenue.
--
-- NOTE: buyout components (fact_museum_guided_tour_buyout) and the
-- issued/unissued split of the ORIGINAL Pentaho flow are consolidated here
-- into recognized-line revenue. Confirm buyout handling with Chris Wogas
-- before go-live (flagged in build notes).

{{ config(materialized='view') }}

with lines as (
    select * from {{ ref('silver_gateway__ticket_journal_lines') }}
    where ga_flag = 0
),

tour_plu as (
    select plu, dpr_line_item
    from {{ ref('seed_tour_plu') }}
),

-- Any PLU present in the seed is NOT a core museum guided tour (it is a field
-- trip, revealed, architecture, ask-educator, etc.). This replaces the former
-- hardcoded exclusion list.
labeled as (
    select
        l.*,
        tp.dpr_line_item                                                   as plu_line_item
    from lines l
    left join tour_plu tp on l.plu = tp.plu
),

aggregated as (
    select
        key_date,

        -- Museum guided tours: TOU matrix, excluding any seed-listed PLU
        sum(case when matrix_code like '%TOU%' and plu_line_item is null
                 then quantity else 0 end)                                 as mus_guided_tours,
        sum(case when matrix_code like '%TOU%' and plu_line_item is null
                 then amount else 0 end)                                   as mus_guided_tour_revenue,

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

        -- Virtual Memorial Tour (matrix pattern)
        sum(case when matrix_code like '%VTM%' then quantity else 0 end)   as virtual_mem_tours,
        sum(case when matrix_code like '%VTM%' then amount else 0 end)     as virtual_mem_tour_revenue,

        -- Virtual Museum Tour (matrix pattern)
        sum(case when matrix_code like '%VTU%' then quantity else 0 end)   as virtual_mus_tours,
        sum(case when matrix_code like '%VTU%' then amount else 0 end)     as virtual_mus_tour_revenue,

        -- Virtual Youth & Family Memorial Tour (matrix pattern)
        sum(case when matrix_code like '%VTF%' then quantity else 0 end)   as virtual_yf_mem_tours,
        sum(case when matrix_code like '%VTF%' then amount else 0 end)     as virtual_yf_mem_tour_revenue

    from labeled
    group by key_date
)

select * from aggregated
