-- Test (reconciliation): the split Gateway donation cohorts add back to the whole cohort
-- Severity: error — 8.9.0 builds vs_cart_don and kiosk_coatcheck_donations as
-- SUMS OF COMPLEMENTS rather than re-reading the source cohort, precisely so no
-- donation total is authored twice (ADR-021). That construction is only correct
-- if the complements actually partition the cohort. This test reads the cohort
-- straight from int_gateway__item_journal_lines with legacy's own predicates
-- (t_fact_all_gateway_donations_new: the two %DON-OPS-MEM% / %DON-OPS-MUS%
-- matrix patterns with `and JNLDetails.Qty <> 0`) and asserts the recomposition
-- is exact. If a new box-office PLU is introduced and lands in neither the
-- named-PLU branch nor its complement, this catches it before the dollars
-- vanish from a live report.

with source_cohorts as (
    select
        date_key,
        -- Legacy vs_cart_donations: dim_galaxy_items.account_idno like '%DON-OPS-MEM%'
        sum(case when matrix_code like '%DON-OPS-MEM%'
                  and coalesce(quantity, 0) <> 0
                 then amount else 0 end)                                    as mem_cohort,
        -- Legacy coatcheck_donations: account_idno like '%DON-OPS-MUS%'
        sum(case when matrix_code like '%DON-OPS-MUS%'
                  and coalesce(quantity, 0) <> 0
                 then amount else 0 end)                                    as mus_cohort
    from {{ ref('int_gateway__item_journal_lines') }}
    group by date_key
),

fact as (
    select
        date_key,
        vs_cart_don,
        kiosk_coatcheck_donations,
        coatcheck_don,
        box_office_mus_exit_don
    from {{ ref('fct_donations') }}
),

compared as (
    select
        coalesce(f.date_key, s.date_key)                                    as date_key,
        coalesce(s.mem_cohort, 0)                                           as source_mem_cohort,
        coalesce(f.vs_cart_don, 0)                                          as fact_vs_cart_don,
        coalesce(s.mus_cohort, 0)                                           as source_mus_cohort,
        -- The legacy Donations Analysis Report's coatcheck_don is the WHOLE
        -- %DON-OPS-MUS% cohort; the platform splits the exit box out of it.
        coalesce(f.coatcheck_don, 0) + coalesce(f.box_office_mus_exit_don, 0) as fact_mus_cohort,
        coalesce(s.mem_cohort, 0) + coalesce(s.mus_cohort, 0)               as source_kiosk_coatcheck,
        coalesce(f.kiosk_coatcheck_donations, 0)                            as fact_kiosk_coatcheck
    from fact f
    full outer join source_cohorts s on f.date_key = s.date_key
)

select *
from compared
where abs(source_mem_cohort      - fact_vs_cart_don)      > 0.01
   or abs(source_mus_cohort      - fact_mus_cohort)       > 0.01
   or abs(source_kiosk_coatcheck - fact_kiosk_coatcheck)  > 0.01
