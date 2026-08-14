-- Test (reconciliation): the unissued audit companions equal the unissued source
-- Severity: error — fct_daily_performance carries unissued_tickets_sold,
-- unissued_ticket_revenue and unissued_ticketing_donations so the ADR-005 impact
-- of the recognition change stays measurable. If those companions drift from
-- int_gateway__unissued_order_lines, the reported impact is wrong even though the
-- headline measures may look fine — which is the worst failure mode for a gated
-- release. The predicates below are the SEED-driven ones int_dpr__admissions and
-- int_dpr__donations apply, not a second copy of the exclusion lists.

with fact as (
    select
        date_key,
        unissued_tickets_sold,
        unissued_ticket_revenue,
        unissued_ticketing_donations
    from {{ ref('fct_daily_performance') }}
),

labeled as (
    select
        u.date_key,
        u.cohort,
        u.plu,
        u.matrix_code,
        u.ga_flag,
        u.qty_unissued,
        u.amt_unissued,
        (tse.plu is not null)   as is_tickets_sold_excluded,
        (tre.plu is not null)   as is_ticket_revenue_excluded
    from {{ ref('int_gateway__unissued_order_lines') }} u
    left join {{ ref('seed_gateway_tickets_sold_excluded_plu') }}   tse on u.plu = tse.plu
    left join {{ ref('seed_gateway_ticket_revenue_excluded_plu') }} tre on u.plu = tre.plu
),

source as (
    select
        date_key,
        sum(case when ga_flag = 1 and cohort = 'museum_tickets'
                  and (matrix_code like '%GAD%' or matrix_code like '%TOU%')
                  and matrix_code not like '%XGA%'
                  and not is_tickets_sold_excluded
                 then qty_unissued else 0 end)
          + sum(case when ga_flag = 1 and cohort = 'mem_tour_mus_admission'
                     then qty_unissued else 0 end)                          as unissued_tickets_sold,
        sum(case when ga_flag = 1 and cohort = 'museum_tickets'
                  and (matrix_code like '%GAD%' or matrix_code like '%TOU%')
                  and not is_ticket_revenue_excluded
                 then amt_unissued else 0 end)
          + sum(case when ga_flag = 1 and cohort = 'mem_tour_mus_admission'
                     then amt_unissued else 0 end)                          as unissued_ticket_revenue,
        sum(case when cohort = 'ticketing_donations' and plu <> 'DONMBRMUS001'
                 then amt_unissued else 0 end)                              as unissued_ticketing_donations
    from labeled
    group by date_key
)

select
    coalesce(f.date_key, s.date_key)    as date_key,
    f.unissued_tickets_sold             as fact_tickets,
    s.unissued_tickets_sold             as source_tickets,
    f.unissued_ticket_revenue           as fact_revenue,
    s.unissued_ticket_revenue           as source_revenue,
    f.unissued_ticketing_donations      as fact_donations,
    s.unissued_ticketing_donations      as source_donations
from fact f
full outer join source s on f.date_key = s.date_key
where abs(coalesce(f.unissued_tickets_sold, 0)        - coalesce(s.unissued_tickets_sold, 0))        > 0.0001
   or abs(coalesce(f.unissued_ticket_revenue, 0)      - coalesce(s.unissued_ticket_revenue, 0))      > 0.01
   or abs(coalesce(f.unissued_ticketing_donations, 0) - coalesce(s.unissued_ticketing_donations, 0)) > 0.01
