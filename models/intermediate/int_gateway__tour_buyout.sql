-- Silver intermediate: guided-tour buyout lines (revenue with suppressed quantity)
-- ---------------------------------------------------------------------------
-- Domain: admissions / tours
-- Grain: one row per date_key x plu x source_leg
--
-- Recreates 911dw.fact_museum_guided_tour_buyout. A "buyout" is a whole-tour
-- purchase: the legacy estate EXCLUDES the buyout categories from the tour line
-- grain and then ADDS this table back, so the revenue is recognised once and,
-- for three of the seven PLUs, WITHOUT a tour count. Feeds int_dpr__tour_revenue.
--
-- Legacy lineage: t_fact_museum_guided_tour_buyout (both TableInput steps),
-- consumed by t_reporting_mus_guided_tours_revenue (categories
-- 1077,1430,1922,2226,2831,2826), t_reporting_mem_guided_tours_revenue
-- (2219,2220) and t_reporting_early_access_tours_revenue (2112,2228).
--
-- QUANTITY SUPPRESSION (the reason this model exists separately):
--   CASE WHEN jnlTickets.plu IN ('MEMGTOBUY001','MUSGTOBUY007','MUSGTOBUY009')
--        THEN 0 ELSE JnlDetails.Qty END
-- Buyout REVENUE counts for those three PLUs; the tour COUNT does not, because a
-- buyout is one transaction rather than N admissions. The flag lives in
-- seed_tour_buyout_plu.suppress_quantity, alongside the PLU list itself.
--
-- SCOPE NOTE (ADR-005 gate) — owner Chris Wogas. Three deviations from legacy,
-- all forced by what is staged. See DECISION_MEMO.
-- * LINE ASSIGNMENT. Legacy adds the buyout back by key_museum_category. The
--   category -> PLU crosswalk (911dw.dim_galaxy_items) is not staged, so the
--   assignment is made per PLU in seed_tour_buyout_plu and is a judgement, not a
--   derivation. seed_tour_buyout_category carries the legacy category lists as a
--   reviewable register with is_resolved = FALSE throughout.
-- * DATE BASIS. Legacy keys the buyout on rmEvents.startDateTime. rme.start_at is
--   NULL for ~95% of journal rows in the staged extract (documented in the
--   gateway_recognized_date macro), so this model uses the shared recognized
--   date_key from int_gateway__ticket_journal_lines, whose basis-182 branch is
--   coalesce(rme.start_at, end_of_life_date, ticket_date) — the same event/visit
--   date, with the blessed fallback. Restoring the true event date is the open
--   follow-up already recorded on that macro.
-- * SOURCE. Legacy re-joins JnlHeaders/JnlDetails/jnlTickets/rmEvents/Items/
--   vAttribute from scratch and applies no COA join and no customer/PLU
--   exclusions. This model reads the shared enriched journal, which DOES apply
--   the COA join and the seed_gateway_excluded_plu / _customer filters. That is
--   deliberate (one enrichment, one exclusion policy) but means a buyout line
--   whose customer is on the exclusion list is dropped here and was not dropped
--   in Pentaho.
--
-- ADR-001: reads only from stg_ / int_.
-- ADR-004: all business logic lives here, not in Power BI.

{{ config(materialized='view') }}

with buyout_plu as (
    select
        plu,
        buyout_line_item,
        suppress_quantity
    from {{ ref('seed_tour_buyout_plu') }}
),

journal_lines as (
    select
        date_key,
        plu,
        matrix_code,
        quantity,
        amount
    from {{ ref('int_gateway__ticket_journal_lines') }}
),

journal_leg as (
    -- Leg 1: the buyout journal lines themselves.
    select
        jl.date_key,
        jl.plu,
        b.buyout_line_item,
        jl.matrix_code,
        'journal'                                                          as source_leg,
        b.suppress_quantity,
        jl.quantity,
        jl.amount
    from journal_lines jl
    inner join buyout_plu b on jl.plu = b.plu
),

additional_revenue_leg as (
    -- Leg 2: "Guided Tour Buyout Additional Revenue" — the second TableInput of
    -- t_fact_museum_guided_tour_buyout:
    --   select convert(varchar(12), Expiration, 112) as key_date, PLU,
    --          0 as Qty, Price, Tax
    --   from Tickets where PLU = 'TOUADDREV002'
    -- BUILDABLE: stg_gateway__tickets exposes plu, expires_at (source
    -- `expiration`), price and tax, so the leg is reproduced exactly, including
    -- the hard-coded zero quantity.
    -- NOT ATTRIBUTABLE: the legacy row lands in fact_museum_guided_tour_buyout
    -- with a key_museum_category looked up from dim_galaxy_items, and the three
    -- consuming reports each filter on a category list. Without that crosswalk
    -- we cannot say which DPR line TOUADDREV002 belongs to, so buyout_line_item
    -- is a typed NULL — cause: BLOCKED ON A BUSINESS RULE (DECISION_MEMO
    -- question 1). int_dpr__tour_revenue therefore does not consume this leg;
    -- it is materialised so the dollars are visible and can be wired the moment
    -- the line is confirmed.
    select
        cast(t.expires_at as date)                                         as date_key,
        trim(t.plu)                                                        as plu,
        cast(null as varchar)                                              as buyout_line_item,
        cast(null as varchar)                                              as matrix_code,
        'tour_additional_revenue'                                          as source_leg,
        false                                                              as suppress_quantity,
        0                                                                  as quantity,
        coalesce(t.price, 0)                                               as amount
    from {{ ref('stg_gateway__tickets') }} t
    where trim(t.plu) = 'TOUADDREV002'
      and t.expires_at is not null
),

combined as (
    select * from journal_leg
    union all
    select * from additional_revenue_leg
)

select
    date_key,
    plu,
    buyout_line_item,
    source_leg,
    max(matrix_code)                                                       as matrix_code,
    boolor_agg(suppress_quantity)                                          as is_quantity_suppressed,
    -- Legacy CASE: suppressed PLUs contribute revenue but zero tours.
    sum(case when suppress_quantity then 0 else quantity end)              as buyout_tours,
    -- Carried unsuppressed so the suppression is auditable without re-deriving it.
    sum(quantity)                                                          as buyout_tours_unsuppressed,
    sum(amount)                                                            as buyout_revenue
from combined
where date_key is not null
group by date_key, plu, buyout_line_item, source_leg
