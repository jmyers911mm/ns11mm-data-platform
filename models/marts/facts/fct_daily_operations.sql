-- Marts fact: daily museum operations (ticket sales + gate scans + retail)
-- ---------------------------------------------------------------------------
-- Domain: operations
-- Grain:  one row per visit_date
--
-- Full-outer-joins daily ticket sales (int_pos_tickets), gate scans
-- (int_ticket_scans) and CounterPoint retail (int_counterpoint__retail_lines)
-- into a single day-grain operations fact: visitors admitted, valid/rejected
-- scans, active gates, ticket transactions/revenue/discounts, identified
-- buyers, retail transactions/revenue, and a total_revenue rollup.
--
-- MATERIALIZATION: table (matches fct_daily_scan / fct_daily_performance /
-- fct_retail_daily). This model aggregates to day grain, so an incremental
-- `merge` on visit_date over a windowed sum would OVERWRITE a day's totals with
-- only the newly-arrived slice whenever late/corrected rows land for a day that
-- already exists -- silently undercounting. A full table rebuild is small here
-- and always correct; do not switch this back to incremental without moving to
-- delete+insert on the affected visit_dates recomputed from full history.
--
-- SCOPE NOTE (ADR-005 gate, 8.7.0) — owner Chris Wogas: total_visitors is now
-- the legacy NET passes-scanned measure. int_ticket_scans applies the
-- t_fact_museum_passes_scanned rule (Status = 0 + Code = 0 adds, Status = 0 +
-- Code = 11 subtracts, all other codes contribute nothing, Gateway facility 13
-- excluded), so total_visitors falls relative to the previous
-- `status in (0,1)` definition. valid_scans / rejected_scans follow the same
-- rule: an admitted entry is code 0, a reversal is code 11 and is counted in
-- reversing_scans (not in either of the other two), and everything else is
-- rejected. gates_active counts gates that produced a COUNTED scan.
--
-- RETAIL SCOPE: retail_revenue is CounterPoint top-line merchandise sales
-- (sale + return amount) EXCLUDING donation-ask lines (is_donation), so it can
-- be added to ticket_revenue for total_revenue without double-counting DPR
-- donation measures. To include donations instead, drop the `not is_donation`
-- filter in the retail CTE. retail_discounts stays 0: the staged CounterPoint
-- tables carry no line-level discount field (confirm the source with Gennady
-- before publishing a discount metric). Feeds ml_visitor_forecast_training.
--
-- ADR-004: all business logic lives here, not in Power BI.

{{
    config(
        materialized='table',
        cluster_by=['visit_date'],
        tags=['daily', 'critical']
    )
}}

with ticket_sales as (
    select
        transaction_date                                    as visit_date,
        count(distinct transaction_id)                      as ticket_transactions,
        sum(quantity)                                       as tickets_sold,
        -- POS-derived (int_pos_tickets price x quantity). NOT the same measure
        -- as fct_daily_performance.ticket_revenue (GA journal-line amounts) —
        -- the shared column name is historical; do not compare the two by name.
        sum(total_amount)                                   as ticket_revenue,
        sum(discount_amount)                                as ticket_discounts,
        count(distinct case when has_email then customer_email end) as identified_visitors
    from {{ ref('int_pos_tickets') }}
    group by 1
),

scans as (
    select
        scan_date                                           as visit_date,
        -- net_visitor_count is signed and already 0 for uncounted scans, so
        -- this single SUM reproduces the legacy UNION of the +code-0 and
        -- -code-11 legs.
        sum(coalesce(net_visitor_count, 0))                 as total_visitors_admitted,
        count(case when is_valid_scan then 1 end)           as valid_scans,
        count(case when is_reversing_scan then 1 end)       as reversing_scans,
        count(case when not is_counted_scan then 1 end)     as rejected_scans,
        count(distinct case when is_counted_scan then gate_id end) as gates_active
    from {{ ref('int_ticket_scans') }}
    group by 1
),

retail as (
    -- CounterPoint merchandise sales, day grain. Non-donation lines only
    -- (donation-ask lines are DPR donation measures, not retail revenue).
    -- Inner join to dim_date guards the referential_integrity no_orphan_dates
    -- test: retail can only contribute a visit_date that exists in the calendar
    -- dimension, so a null / out-of-range business_date here cannot create an
    -- orphan. (Ticket/scan orphans, if any, are pre-existing and unaffected.)
    select
        cast(r.business_date as date)                       as visit_date,
        count(distinct case when not r.is_donation then r.doc_id end)                     as retail_transactions,
        sum(case when not r.is_donation then r.net_amount else 0 end)  as retail_revenue
    from {{ ref('int_counterpoint__retail_lines') }} r
    inner join {{ ref('dim_date') }} dd
        on cast(r.business_date as date) = dd.date_key
    -- 8.2.0: int_counterpoint__retail_lines fans a POS line out to every
    -- reporting facility whose scope claims it, because legacy t_fact_retail
    -- treats facility as a reporting view rather than a partition (store 8 is
    -- both Preview/Vesey 1001 and Museum Store 1003; store 10 is both 1003 and
    -- Atrium 1030; store 1 is both 1001 and Cafe 4007). This model aggregates
    -- to DAY grain with no facility in the group by, so without this predicate
    -- those three stores' revenue and transactions would count two or three
    -- times. is_primary_facility is true on exactly one scope row per line.
    where r.is_primary_facility
    group by 1
)

select
    coalesce(t.visit_date, s.visit_date, r.visit_date)      as visit_date,
    coalesce(s.total_visitors_admitted, 0)                  as total_visitors,
    coalesce(s.valid_scans, 0)                              as valid_scans,
    coalesce(s.reversing_scans, 0)                          as reversing_scans,
    coalesce(s.rejected_scans, 0)                           as rejected_scans,
    coalesce(s.gates_active, 0)                             as gates_active,
    coalesce(t.ticket_transactions, 0)                      as ticket_transactions,
    coalesce(t.tickets_sold, 0)                             as tickets_sold,
    coalesce(t.ticket_revenue, 0)                           as ticket_revenue,
    coalesce(t.ticket_discounts, 0)                         as ticket_discounts,
    coalesce(t.identified_visitors, 0)                      as identified_ticket_buyers,
    coalesce(r.retail_transactions, 0)                      as retail_transactions,
    coalesce(r.retail_revenue, 0)                           as retail_revenue,
    0                                                       as retail_discounts,  -- no discount field in staged CounterPoint data
    coalesce(t.ticket_revenue, 0)
      + coalesce(r.retail_revenue, 0)                       as total_revenue,
    coalesce(
        coalesce(r.retail_revenue, 0)
          / nullif(coalesce(s.total_visitors_admitted, 0), 0),
        0)                                                  as retail_revenue_per_visitor,
    current_timestamp()                                     as _loaded_at
from ticket_sales t
full outer join scans  s on t.visit_date = s.visit_date
full outer join retail r on coalesce(t.visit_date, s.visit_date) = r.visit_date
