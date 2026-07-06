-- Silver DPR: service fees, audio guide/headset, memorial+museum tour
-- ---------------------------------------------------------------------------
-- Domain: revenue / visitor services
-- Grain:  one row per key_date
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

fees as (
    select
        key_date,
        -- Museum service fees: matrix like %MUF% and %FEE%
        sum(case when matrix_code like '%MUF%' and matrix_code like '%FEE%'
                 then amount else 0 end)                                    as museum_service_fees,
        -- Memorial service fees: matrix like %MEF% and %FEE%
        sum(case when matrix_code like '%MEF%' and matrix_code like '%FEE%'
                 then amount else 0 end)                                    as memorial_service_fees,

        -- Museum audio guide (JnlItems kind 8) + headset (in item grain proxy):
        -- guide PLUs
        sum(case when plu in ('AUDIO1001','AUDIO0001') and item_kind = 8
                 then amount else 0 end)                                    as mus_audio_guide_revenue,
        sum(case when plu in ('AUDIO1001','AUDIO0001') and item_kind = 8
                 then quantity else 0 end)                                  as mus_audio_guide_units,

        -- Memorial audio guide (matrix %MAG% online/Galaxy portion)
        sum(case when matrix_code like '%MAG%'
                 then amount else 0 end)                                    as mem_audio_guide_revenue

    from item_lines
    group by key_date
),

mem_mus_tour as (
    -- Memorial + Museum combined tour product cohort.
    -- Legacy fact_memorial_museum_tour is fed by t_fact_memorial_museum_tour
    -- from the same Galaxy journal join; identified here by matrix %MTG%.
    select
        key_date,
        sum(case when matrix_code like '%MTG%' then quantity else 0 end)   as mem_mus_tours,
        sum(case when matrix_code like '%MTG%' then amount else 0 end)     as mem_mus_tour_revenue
    from ticket_lines
    group by key_date
),

date_spine as (
    select key_date from fees
    union
    select key_date from mem_mus_tour
)

select
    d.key_date,
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
left join fees          f on d.key_date = f.key_date
left join mem_mus_tour  t on d.key_date = t.key_date
