-- Silver intermediate: guided-tour, virtual-tour, field-trip, and program revenue
-- ---------------------------------------------------------------------------
-- Domain: admissions / tours
-- Grain: one row per date_key
--
-- Recreates the DPR tour-family line items from three sources the legacy estate
-- adds together and the platform previously carried only one of:
--   1. ISSUED journal lines   (int_gateway__ticket_journal_lines)
--   2. UNISSUED order lines   (int_gateway__unissued_order_lines)      [8.8.0]
--   3. BUYOUT lines           (int_gateway__tour_buyout)               [8.8.0]
-- Each measure is (quantity, revenue) for a product cohort selected by matrix
-- code and/or PLU, all with ga_flag = 0 (tour, not general admission).
--
-- PLU-enumerable cohorts (field trips, revealed, ask-educator, youth & family,
-- early access, and the set of PLUs excluded from core museum guided tours) are
-- seed-driven via seed_tour_plu. The seven BUYOUT PLUs are seed-driven via
-- seed_tour_buyout_plu. A PLU in EITHER seed is excluded from the core museum /
-- memorial guided-tour cohorts, which is how the legacy
--   "exclude the buyout categories from the line grain, then add the buyout
--    fact back"
-- pattern is reproduced without double counting. Matrix-code cohorts (%TOU%,
-- %MGT%, %VTM%, %VTU%, %VTF%) stay inline because they are pattern matches over
-- an open set of PLUs, not an enumerable list.
--
-- Legacy lineage: t_reporting_mus_guided_tours_revenue,
-- t_reporting_mem_guided_tours_revenue, t_reporting_virtual_*_revenue,
-- t_reporting_mus_field_trip_revenue, t_reporting_mem_field_trip_revenue,
-- t_reporting_revealed_tour_revenue, t_reporting_ask_educator,
-- t_reporting_youth_fam_tours_revenue, t_reporting_early_access_tours_revenue,
-- t_fact_museum_guided_tour_buyout.
--
-- 8.1.0 DOUBLE-COUNT FIX, PRESERVED: the revealed tour (VTMUSOBLOADW001) carries
-- a %VTM% matrix code and was counted once as revealed_tour_revenue and again as
-- virtual_mem_tour_revenue, with rpt_dpr_report_long adding both into
-- TOTAL_TOUR_REVENUE. The virtual-memorial cohort excludes the seed-labelled
-- revealed PLU, on BOTH the issued and the new unissued leg.
--
-- SCOPE NOTE (ADR-005 gate) — owner Chris Wogas. This release changes what every
-- tour line COUNTS and what it EARNS. See DECISION_MEMO.
-- * BUYOUT QUANTITY SUPPRESSION. Three buyout PLUs contribute revenue but zero
--   tours (legacy CASE in t_fact_museum_guided_tour_buyout). Tour counts on the
--   DPR therefore fall while tour revenue rises.
-- * UNISSUED RECOGNITION. Tour revenue now includes lines that are sold but not
--   yet ticketed, recognised on the event date. Every tour revenue line rises.
-- * NEW ACTUALS. youth_fam_* and early_access_* / ea_mem_mus_* were previously
--   budget-only on the DPR (rpt_dpr_budget_daily maps the budget columns into
--   line items with no actual behind them). They now have actuals. The layout
--   seeds still describe those rows as budget-only; wiring them into
--   rpt_dpr_powerbi / rpt_dpr_report_long is deliberately NOT done in this
--   release — it is a separate report-layer change that needs its own sign-off.
-- * LEGACY QUIRK NOT REPRODUCED. t_reporting_early_access_tours_revenue filters
--   the ISSUED leg with `f.ga_flag = 0` but the UNISSUED leg with `and f.ga_flag`
--   (truthy, i.e. ga_flag = 1). The two legs of the same measure disagree. This
--   model uses ga_flag = 0 on both, matching the issued leg and every other tour
--   measure. Flagged for confirmation.
--
-- ADR-004: all business logic lives here, not in Power BI.

{{ config(materialized='view') }}

with lines as (
    select * from {{ ref('int_gateway__ticket_journal_lines') }}
    where ga_flag = 0
),

unissued as (
    select * from {{ ref('int_gateway__unissued_order_lines') }}
    where ga_flag = 0
),

buyout as (
    select * from {{ ref('int_gateway__tour_buyout') }}
    -- The TOUADDREV002 leg carries a NULL buyout_line_item (no category
    -- crosswalk); it is deliberately not added to any DPR line here.
    where buyout_line_item is not null
),

tour_plu as (
    select plu, dpr_line_item
    from {{ ref('seed_tour_plu') }}
),

buyout_plu as (
    select plu
    from {{ ref('seed_tour_buyout_plu') }}
),

-- Any PLU present in seed_tour_plu is NOT a core museum/memorial guided tour (it
-- is a field trip, revealed, architecture, ask-educator, youth & family or early
-- access). Any PLU present in seed_tour_buyout_plu is a buyout and is added back
-- from the buyout model instead, so it must not also count at line grain.
labeled_issued as (
    select
        l.date_key,
        l.plu,
        l.matrix_code,
        l.quantity,
        l.amount,
        tp.dpr_line_item                                                   as plu_line_item,
        bp.plu is not null                                                 as is_buyout_plu
    from lines l
    left join tour_plu   tp on l.plu = tp.plu
    left join buyout_plu bp on l.plu = bp.plu
),

labeled_unissued as (
    select
        u.date_key,
        u.plu,
        u.matrix_code,
        u.cohort,
        u.qty_unissued                                                     as quantity,
        u.amt_unissued                                                     as amount,
        tp.dpr_line_item                                                   as plu_line_item,
        bp.plu is not null                                                 as is_buyout_plu
    from unissued u
    left join tour_plu   tp on u.plu = tp.plu
    left join buyout_plu bp on u.plu = bp.plu
),

issued_agg as (
    select
        date_key,

        -- Museum guided tours: TOU matrix, excluding seed-listed and buyout PLUs
        sum(case when matrix_code like '%TOU%' and plu_line_item is null and not is_buyout_plu
                 then quantity else 0 end)                                 as mus_guided_tours,
        sum(case when matrix_code like '%TOU%' and plu_line_item is null and not is_buyout_plu
                 then amount else 0 end)                                   as mus_guided_tour_revenue,

        -- Memorial guided tours: MGT matrix, excluding seed-listed and buyout PLUs.
        -- Distinct from mem_mus_tour (%MTG%, combined) and from field trips
        -- (seed-labeled), so no double-count.
        sum(case when matrix_code like '%MGT%' and plu_line_item is null and not is_buyout_plu
                 then quantity else 0 end)                                 as mem_guided_tours,
        sum(case when matrix_code like '%MGT%' and plu_line_item is null and not is_buyout_plu
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

        -- Youth & Family tours (seed-labeled). New actual in 8.8.0.
        sum(case when plu_line_item = 'youth_fam_tour' then quantity else 0 end)
                                                                           as youth_fam_tours,
        sum(case when plu_line_item = 'youth_fam_tour' then amount else 0 end)
                                                                           as youth_fam_tour_revenue,

        -- Early Access tours (seed-labeled). New actual in 8.8.0.
        sum(case when plu_line_item = 'early_access_tour' then quantity else 0 end)
                                                                           as early_access_tours,
        sum(case when plu_line_item = 'early_access_tour' then amount else 0 end)
                                                                           as early_access_tour_revenue,

        -- All-Inclusive Early Access (memorial + museum). New actual in 8.8.0.
        sum(case when plu_line_item = 'ea_mem_mus_tour' then quantity else 0 end)
                                                                           as ea_mem_mus_tours,
        sum(case when plu_line_item = 'ea_mem_mus_tour' then amount else 0 end)
                                                                           as ea_mem_mus_tour_revenue,

        -- Virtual Memorial Tour (matrix pattern), less the revealed-tour PLU.
        -- 8.1.0 double-count fix, preserved: the revealed tour (VTMUSOBLOADW001)
        -- carries a %VTM% matrix code but reports on its own line; without this
        -- carve-out it is counted in both revealed_tour_revenue and
        -- virtual_mem_tour_revenue, and rpt_dpr_report_long adds BOTH into
        -- TOTAL_TOUR_REVENUE.
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

    from labeled_issued
    group by date_key
),

unissued_agg as (
    -- Legacy adds the unissued leg to the SAME measures with the SAME filters.
    -- Museum guided tours read the museum_tickets cohort (%TOU%); memorial guided
    -- tours read both the memorial_tours cohort (%MGT% + %XGA%) and the
    -- mem_tour_mus_admission cohort (%MGT% + %XXX%), matching the two separate
    -- legacy steps in t_reporting_mem_guided_tours_revenue.
    select
        date_key,

        sum(case when cohort = 'museum_tickets' and matrix_code like '%TOU%'
                  and plu_line_item is null and not is_buyout_plu
                 then quantity else 0 end)                                 as mus_guided_tours,
        sum(case when cohort = 'museum_tickets' and matrix_code like '%TOU%'
                  and plu_line_item is null and not is_buyout_plu
                 then amount else 0 end)                                   as mus_guided_tour_revenue,

        sum(case when cohort in ('memorial_tours', 'mem_tour_mus_admission')
                  and plu_line_item is null and not is_buyout_plu
                 then quantity else 0 end)                                 as mem_guided_tours,
        sum(case when cohort in ('memorial_tours', 'mem_tour_mus_admission')
                  and plu_line_item is null and not is_buyout_plu
                 then amount else 0 end)                                   as mem_guided_tour_revenue,

        sum(case when plu_line_item = 'mem_field_trip' then quantity else 0 end)
                                                                           as mem_field_trips,
        sum(case when plu_line_item = 'mem_field_trip' then amount else 0 end)
                                                                           as mem_field_trip_revenue,

        sum(case when plu_line_item = 'mus_field_trip' then quantity else 0 end)
                                                                           as mus_field_trips,
        sum(case when plu_line_item = 'mus_field_trip' then amount else 0 end)
                                                                           as mus_field_trip_revenue,

        sum(case when plu_line_item = 'revealed_tour' then amount else 0 end)
                                                                           as revealed_tour_revenue,

        sum(case when plu_line_item = 'ask_educator' then amount else 0 end)
                                                                           as ask_educator_revenue,

        sum(case when plu_line_item = 'youth_fam_tour' then quantity else 0 end)
                                                                           as youth_fam_tours,
        sum(case when plu_line_item = 'youth_fam_tour' then amount else 0 end)
                                                                           as youth_fam_tour_revenue,

        sum(case when plu_line_item = 'early_access_tour' then quantity else 0 end)
                                                                           as early_access_tours,
        sum(case when plu_line_item = 'early_access_tour' then amount else 0 end)
                                                                           as early_access_tour_revenue,

        sum(case when plu_line_item = 'ea_mem_mus_tour' then quantity else 0 end)
                                                                           as ea_mem_mus_tours,
        sum(case when plu_line_item = 'ea_mem_mus_tour' then amount else 0 end)
                                                                           as ea_mem_mus_tour_revenue,

        -- 8.1.0 revealed-tour carve-out, applied to the unissued leg too.
        sum(case when matrix_code like '%VTM%'
                  and coalesce(plu_line_item, '') <> 'revealed_tour'
                 then quantity else 0 end)                                 as virtual_mem_tours,
        sum(case when matrix_code like '%VTM%'
                  and coalesce(plu_line_item, '') <> 'revealed_tour'
                 then amount else 0 end)                                   as virtual_mem_tour_revenue,
        sum(case when matrix_code like '%VTU%' then quantity else 0 end)   as virtual_mus_tours,
        sum(case when matrix_code like '%VTU%' then amount else 0 end)     as virtual_mus_tour_revenue,
        sum(case when matrix_code like '%VTF%' then quantity else 0 end)   as virtual_yf_mem_tours,
        sum(case when matrix_code like '%VTF%' then amount else 0 end)     as virtual_yf_mem_tour_revenue

    from labeled_unissued
    group by date_key
),

buyout_agg as (
    -- buyout_tours is already quantity-suppressed for the three legacy PLUs.
    select
        date_key,
        sum(case when buyout_line_item = 'mus_guided_tour'   then buyout_tours   else 0 end) as mus_guided_tours,
        sum(case when buyout_line_item = 'mus_guided_tour'   then buyout_revenue else 0 end) as mus_guided_tour_revenue,
        sum(case when buyout_line_item = 'mem_guided_tour'   then buyout_tours   else 0 end) as mem_guided_tours,
        sum(case when buyout_line_item = 'mem_guided_tour'   then buyout_revenue else 0 end) as mem_guided_tour_revenue,
        sum(case when buyout_line_item = 'early_access_tour' then buyout_tours   else 0 end) as early_access_tours,
        sum(case when buyout_line_item = 'early_access_tour' then buyout_revenue else 0 end) as early_access_tour_revenue,
        sum(buyout_tours)                                                                     as buyout_tours_total,
        sum(buyout_tours_unsuppressed)                                                        as buyout_tours_unsuppressed_total,
        sum(buyout_revenue)                                                                   as buyout_revenue_total
    from buyout
    group by date_key
),

date_spine as (
    select date_key from issued_agg
    union select date_key from unissued_agg
    union select date_key from buyout_agg
)

select
    s.date_key,

    -- Guided tours: issued + unissued + buyout
    coalesce(i.mus_guided_tours, 0) + coalesce(u.mus_guided_tours, 0)
      + coalesce(b.mus_guided_tours, 0)                                    as mus_guided_tours,
    coalesce(i.mus_guided_tour_revenue, 0) + coalesce(u.mus_guided_tour_revenue, 0)
      + coalesce(b.mus_guided_tour_revenue, 0)                             as mus_guided_tour_revenue,
    coalesce(i.mem_guided_tours, 0) + coalesce(u.mem_guided_tours, 0)
      + coalesce(b.mem_guided_tours, 0)                                    as mem_guided_tours,
    coalesce(i.mem_guided_tour_revenue, 0) + coalesce(u.mem_guided_tour_revenue, 0)
      + coalesce(b.mem_guided_tour_revenue, 0)                             as mem_guided_tour_revenue,

    -- Field trips: issued + unissued
    coalesce(i.mem_field_trips, 0) + coalesce(u.mem_field_trips, 0)        as mem_field_trips,
    coalesce(i.mem_field_trip_revenue, 0) + coalesce(u.mem_field_trip_revenue, 0)
                                                                           as mem_field_trip_revenue,
    coalesce(i.mus_field_trips, 0) + coalesce(u.mus_field_trips, 0)        as mus_field_trips,
    coalesce(i.mus_field_trip_revenue, 0) + coalesce(u.mus_field_trip_revenue, 0)
                                                                           as mus_field_trip_revenue,

    coalesce(i.revealed_tour_revenue, 0) + coalesce(u.revealed_tour_revenue, 0)
                                                                           as revealed_tour_revenue,
    coalesce(i.ask_educator_revenue, 0) + coalesce(u.ask_educator_revenue, 0)
                                                                           as ask_educator_revenue,

    -- Youth & Family and Early Access: new actuals (issued + unissued [+ buyout])
    coalesce(i.youth_fam_tours, 0) + coalesce(u.youth_fam_tours, 0)        as youth_fam_tours,
    coalesce(i.youth_fam_tour_revenue, 0) + coalesce(u.youth_fam_tour_revenue, 0)
                                                                           as youth_fam_tour_revenue,
    coalesce(i.early_access_tours, 0) + coalesce(u.early_access_tours, 0)
      + coalesce(b.early_access_tours, 0)                                  as early_access_tours,
    coalesce(i.early_access_tour_revenue, 0) + coalesce(u.early_access_tour_revenue, 0)
      + coalesce(b.early_access_tour_revenue, 0)                           as early_access_tour_revenue,
    coalesce(i.ea_mem_mus_tours, 0) + coalesce(u.ea_mem_mus_tours, 0)      as ea_mem_mus_tours,
    coalesce(i.ea_mem_mus_tour_revenue, 0) + coalesce(u.ea_mem_mus_tour_revenue, 0)
                                                                           as ea_mem_mus_tour_revenue,

    -- Virtual tours: issued + unissued
    coalesce(i.virtual_mem_tours, 0) + coalesce(u.virtual_mem_tours, 0)    as virtual_mem_tours,
    coalesce(i.virtual_mem_tour_revenue, 0) + coalesce(u.virtual_mem_tour_revenue, 0)
                                                                           as virtual_mem_tour_revenue,
    coalesce(i.virtual_mus_tours, 0) + coalesce(u.virtual_mus_tours, 0)    as virtual_mus_tours,
    coalesce(i.virtual_mus_tour_revenue, 0) + coalesce(u.virtual_mus_tour_revenue, 0)
                                                                           as virtual_mus_tour_revenue,
    coalesce(i.virtual_yf_mem_tours, 0) + coalesce(u.virtual_yf_mem_tours, 0)
                                                                           as virtual_yf_mem_tours,
    coalesce(i.virtual_yf_mem_tour_revenue, 0) + coalesce(u.virtual_yf_mem_tour_revenue, 0)
                                                                           as virtual_yf_mem_tour_revenue,

    -- Audit companions: the size of each newly-added leg, so the ADR-005 impact
    -- is measurable without re-deriving it.
    coalesce(u.mus_guided_tour_revenue, 0) + coalesce(u.mem_guided_tour_revenue, 0)
      + coalesce(u.mem_field_trip_revenue, 0) + coalesce(u.mus_field_trip_revenue, 0)
      + coalesce(u.revealed_tour_revenue, 0) + coalesce(u.ask_educator_revenue, 0)
      + coalesce(u.youth_fam_tour_revenue, 0) + coalesce(u.early_access_tour_revenue, 0)
      + coalesce(u.ea_mem_mus_tour_revenue, 0) + coalesce(u.virtual_mem_tour_revenue, 0)
      + coalesce(u.virtual_mus_tour_revenue, 0) + coalesce(u.virtual_yf_mem_tour_revenue, 0)
                                                                           as unissued_tour_revenue_total,
    coalesce(b.buyout_revenue_total, 0)                                    as buyout_tour_revenue_total,
    coalesce(b.buyout_tours_total, 0)                                      as buyout_tours_total,
    coalesce(b.buyout_tours_unsuppressed_total, 0)                         as buyout_tours_unsuppressed_total

from date_spine s
left join issued_agg   i on s.date_key = i.date_key
left join unissued_agg u on s.date_key = u.date_key
left join buyout_agg   b on s.date_key = b.date_key
