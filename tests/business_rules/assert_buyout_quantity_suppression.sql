-- Test (business_rule): the legacy buyout quantity suppression is applied
-- Severity: error — t_fact_museum_guided_tour_buyout forces the tour COUNT to 0
-- for MEMGTOBUY001 / MUSGTOBUY007 / MUSGTOBUY009 while keeping their revenue.
-- A non-zero count for a suppressed PLU inflates every guided-tour count on the
-- DPR; a zero count for a non-suppressed PLU deflates it.

with buyout as (
    select
        b.date_key,
        b.plu,
        b.source_leg,
        b.buyout_tours,
        b.buyout_tours_unsuppressed,
        b.buyout_revenue,
        s.suppress_quantity
    from {{ ref('int_gateway__tour_buyout') }} b
    left join {{ ref('seed_tour_buyout_plu') }} s on b.plu = s.plu
    where b.source_leg = 'journal'
)

select *
from buyout
where (suppress_quantity and buyout_tours <> 0)
   or (not suppress_quantity and buyout_tours <> buyout_tours_unsuppressed)
   or suppress_quantity is null
