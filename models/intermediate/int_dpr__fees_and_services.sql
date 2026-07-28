-- Silver intermediate: service fees, audio guide/headset, memorial+museum tour
-- Co-authored with CoCo
-- ---------------------------------------------------------------------------
-- Domain: revenue / visitor services
-- Grain: one row per date_key
--
-- Service fees and audio-guide revenue derive from the item-journal grain
-- (JnlItems, jnl_code_id 102-104), not the ticket grain. The memorial+museum
-- combined tour is a ticket-grain measure but is isolated here because it
-- maps 1:1 to legacy fact_memorial_museum_tour rather than a matrix cohort.
--
-- Legacy lineage: t_reporting_service_fees_new,
-- t_reporting_museum_audio_headset_revenue (Galaxy portion),
-- t_reporting_memorial_audio_headset_revenue (Galaxy portion),
-- t_reporting_mem_mus_tours_revenue.
--
-- PLU cohorts are enumerable lists, so they live in seed_service_plu
-- (plu, dpr_line_item, notes) and are joined in, instead of being repeated
-- inside each SUM(CASE). Ops edits that seed to onboard/retire a PLU -- no
-- model change. Mirrors seed_tour_plu. Matrix-code cohorts (%MUF%/%FEE%,
-- %MEF%/%FEE%, %MAG%) stay inline because they are pattern matches over an
-- open set of PLUs, not an enumerable list.
--
-- NOTE: from 2024-01-16 the MUS AG audio revenue also has a CounterPoint
-- component (facility 1060). That portion is added in the mart join, not here,
-- to keep the Galaxy and CounterPoint grains separate (ADR-001 hygiene).

{{ config(materialized='view') }}

with item_lines as (
    select * from {{ ref('int_gateway__item_journal_lines') }}
),

ticket_lines as (
    select * from {{ ref('int_gateway__ticket_journal_lines') }}
),

-- Item-grain audio-guide PLUs (legacy AUDIO1001 / AUDIO0001), from the seed.
service_plu as (
    select plu
    from {{ ref('seed_service_plu') }}
    where dpr_line_item = 'mus_audio_guide'
),

-- Memorial + Museum combined tour cohort (legacy fact_memorial_museum_tour,
-- rItmProductID = 178), from the seed. These PLUs carry NO matrix code, so the
-- former %MTG% matrix filter matched nothing (verified 2026-07-08:
-- MUSMMUADW001 = 1,426 rows / $107,270 with empty matrix_code).
mem_mus_tour_plu as (
    select plu
    from {{ ref('seed_service_plu') }}
    where dpr_line_item = 'mem_mus_tour'
),

fees as (
    select
        il.date_key,
        -- Museum service fees: matrix like %MUF% and %FEE%
        sum(case when il.matrix_code like '%MUF%' and il.matrix_code like '%FEE%'
                 then il.amount else 0 end)                                 as museum_service_fees,
        -- Memorial service fees: matrix like %MEF% and %FEE%
        sum(case when il.matrix_code like '%MEF%' and il.matrix_code like '%FEE%'
                 then il.amount else 0 end)                                 as memorial_service_fees,

        -- Museum audio guide (JnlItems kind 8), PLUs from service_plu cohort
        sum(case when sp.plu is not null and il.item_kind = 8
                 then il.amount else 0 end)                                 as mus_audio_guide_revenue,
        sum(case when sp.plu is not null and il.item_kind = 8
                 then il.quantity else 0 end)                               as mus_audio_guide_units,

        -- Memorial audio guide (matrix %MAG% online/Galaxy portion)
        sum(case when il.matrix_code like '%MAG%'
                 then il.amount else 0 end)                                 as mem_audio_guide_revenue

    from item_lines il
    left join service_plu sp on il.plu = sp.plu
    group by il.date_key
),

mem_mus_tour as (
    -- Product-178 PLUs from the mem_mus_tour_plu cohort (see note above).
    select
        tl.date_key,
        sum(case when mmp.plu is not null then tl.quantity else 0 end)      as mem_mus_tours,
        sum(case when mmp.plu is not null then tl.amount else 0 end)        as mem_mus_tour_revenue
    from ticket_lines tl
    left join mem_mus_tour_plu mmp on tl.plu = mmp.plu
    group by tl.date_key
),

date_spine as (
    select date_key from fees
    union
    select date_key from mem_mus_tour
)

select
    d.date_key,
    coalesce(f.museum_service_fees, 0)
      + coalesce(f.memorial_service_fees, 0)                               as service_fees,
    coalesce(f.museum_service_fees, 0)                                     as museum_service_fees,
    coalesce(f.memorial_service_fees, 0)                                  as memorial_service_fees,
    coalesce(f.mus_audio_guide_revenue, 0)                               as mus_audio_guide_revenue,
    coalesce(f.mus_audio_guide_units, 0)                                 as mus_audio_guide_units,
    coalesce(f.mem_audio_guide_revenue, 0)                               as mem_audio_guide_revenue,
    coalesce(t.mem_mus_tours, 0)                                          as mem_mus_tours,
    coalesce(t.mem_mus_tour_revenue, 0)                                  as mem_mus_tour_revenue
from date_spine d
left join fees          f on d.date_key = f.date_key
left join mem_mus_tour  t on d.date_key = t.date_key