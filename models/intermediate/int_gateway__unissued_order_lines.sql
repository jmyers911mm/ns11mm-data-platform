-- Silver intermediate: unissued (sold, not yet ticketed) Gateway order lines
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing
-- Grain: one row per order_line_id x cohort x leg
--
-- Recreates the four legacy "unissued" facts from the order side of Galaxy.
-- An order line is unissued when issued_quantity < quantity: the sale exists but
-- the ticket has not been printed/issued, so it never reaches the ticket journal
-- that int_gateway__ticket_journal_lines reads. The legacy DPR adds these lines
-- into tickets sold, ticket revenue, museum and memorial tour revenue, youth &
-- family, early access and ticketing donations. Without this model the platform
-- publishes ISSUED-ONLY figures for all of them.
--
-- Legacy lineage:
--   t_fact_museum_tickets_unissued_fordate_new       -> cohort museum_tickets (legs 1,2)
--   t_fact_memorial_guided_tours_unissued_fordate_new -> cohort memorial_tours (legs 1,2)
--   t_fact_mus_tickets_mem_tour_unissued_fordate_refresh -> cohort mem_tour_mus_admission
--   t_fact_museum_ticketing_donations_unissued        -> cohort ticketing_donations
--
-- PRICE DERIVATION (DisbursementDetails.Basis), reproduced verbatim from
-- t_fact_museum_tickets_unissued_fordate_new:
--   disbursement_id <> 0 and Basis <> 'R' and Basis = '$'
--       -> qty_unissued * DisbursementDetails.Price
--   disbursement_id <> 0 and Basis <> 'R' and Basis = '%'
--       -> ((Amount - DiscountAmount) * qty_unissued) / (100 / Price)
--   disbursement_id <> 0 (i.e. Basis = 'R' or null)
--       -> (Amount - DiscountAmount) * qty_unissued
--          - qty_unissued * (select sum(Price) from DisbursementDetails d2
--                            where d2.DisbursementID = DisbursementDetails.DisbursementID)
--   else
--       -> (Amount - DiscountAmount) * (coalesce(quantity,1) - coalesce(issued_quantity,0))
-- Note the ELSE branch's coalesce(quantity, 1) — different from the
-- coalesce(quantity, 0) used everywhere else. That asymmetry is legacy and is
-- preserved. The '%' branch is written algebraically as
-- (Amount - DiscountAmount) * qty * Price / 100, which is identical to
-- X / (100 / Price) but does not divide by zero when Price = 0.
--
-- STAGED-COLUMN CONFIRMATION (every input the Basis CASE needs is present):
--   OrderLines.Quantity/IssuedQuantity/Amount/DiscountAmount/DisbursementID/EventID
--       -> stg_gateway__orderlines.quantity / issued_quantity / amount /
--          discount_amount / disbursement_id / event_id
--   DisbursementDetails.Basis / Price / Name / DisbursementID
--       -> stg_gateway__disbursementdetails.price_basis / price /
--          disbursement_name / disbursement_id
--   Items.PLU / ItemFilter / AttributeValueGroupID
--       -> stg_gateway__items.plu / item_filter / attribute_value_group_id
--   report.vAttribute.rItmMatrixCode -> int_gateway__item_attributes.itm_matrix_code
--   Orders.OpenDate -> stg_gateway__orders.open_date
--   RMEvents.StartDateTime -> stg_gateway__rmevents.start_at
-- No column is missing, so no typed-NULL placeholder is required for the price
-- expression. The one genuine gap is the DATE (see below).
--
-- SCOPE NOTE (ADR-005 gate) — owner Chris Wogas. Two deviations from legacy:
-- * EVENT DATE. Legacy keys every ticket/tour cohort on RMEvents.StartDateTime.
--   rme.start_at is NULL for ~95% of rows in the staged extract (documented on
--   the gateway_recognized_date macro), so event_date_key coalesces
--   start_at -> orderlines.event_ticket_date -> orderlines.ticket_date, the same
--   substitution already blessed for the journal path. order_date_key
--   (Orders.OpenDate) is carried separately and is what the donations cohort uses,
--   exactly as legacy does.
-- * DISBURSEMENT FAN-OUT. Legacy LEFT JOINs DisbursementDetails on
--   disbursement_id, which is one-to-MANY — the same order line is emitted once
--   per disbursement detail, multiplying QtyUnissued, and the Pentaho InsertUpdate
--   silently collapses the duplicates on the target key. Replicating that here
--   would inflate every unissued measure. This model instead takes ONE
--   representative detail per disbursement_id (lowest sequence_no) for Basis /
--   Price / Name, and computes the correlated SUM(Price) separately. That is a
--   deliberate, documented divergence that protects the order-line grain.
--
-- Consumed by int_dpr__admissions, int_dpr__tour_revenue and int_dpr__donations.
-- The DPR-New and Tracker-YTD .prpt queries read the legacy unissued TABLES
-- directly at (key_date, key_museum_category, quantity, amount) grain; this model
-- is the platform equivalent at order-line grain, and the three int_dpr models
-- are where it is aggregated to the day grain those reports consume.
--
-- ADR-001: reads only from stg_ / int_.
-- ADR-004: all business logic lives here, not in Power BI.

{{ config(materialized='table') }}

with order_lines as (
    select
        order_line_id,
        order_id,
        event_id,
        plu,
        quantity,
        issued_quantity,
        amount,
        discount_amount,
        disbursement_id,
        event_ticket_date,
        ticket_date
    from {{ ref('stg_gateway__orderlines') }}
),

orders as (
    select
        order_id,
        open_date
    from {{ ref('stg_gateway__orders') }}
),

items as (
    select
        plu,
        item_filter,
        attribute_value_group_id
    from {{ ref('stg_gateway__items') }}
),

attributes as (
    select avg_id, itm_matrix_code
    from {{ ref('int_gateway__item_attributes') }}
),

events as (
    select event_id, start_at
    from {{ ref('stg_gateway__rmevents') }}
),

disbursement_detail as (
    -- One representative detail per disbursement_id (see scope note).
    select
        disbursement_id,
        price_basis,
        price,
        disbursement_name
    from {{ ref('stg_gateway__disbursementdetails') }}
    qualify row_number() over (
        partition by disbursement_id
        order by sequence_no asc nulls last, disbursement_detail_id asc
    ) = 1
),

disbursement_total as (
    -- The legacy correlated subquery:
    --   (select sum(Price) from DisbursementDetails d2
    --    where d2.DisbursementID = DisbursementDetails.DisbursementID)
    select
        disbursement_id,
        sum(price)                                                         as disbursement_total_price
    from {{ ref('stg_gateway__disbursementdetails') }}
    group by disbursement_id
),

base as (
    select
        ol.order_line_id,
        ol.order_id,
        ol.plu,
        it.item_filter,
        coalesce(a.itm_matrix_code, '')                                    as matrix_code,
        cast(o.open_date as date)                                          as order_date_key,
        cast(coalesce(rme.start_at, ol.event_ticket_date, ol.ticket_date)
             as date)                                                      as event_date_key,
        coalesce(ol.disbursement_id, 0)                                    as disbursement_id,
        dd.price_basis,
        dd.price                                                           as disbursement_price,
        dd.disbursement_name,
        dt.disbursement_total_price,
        coalesce(ol.quantity, 0)                                           as quantity,
        coalesce(ol.issued_quantity, 0)                                    as issued_quantity,
        coalesce(ol.amount, 0)                                             as amount,
        coalesce(ol.discount_amount, 0)                                    as discount_amount,
        coalesce(ol.quantity, 0) - coalesce(ol.issued_quantity, 0)         as qty_unissued,
        -- Legacy ELSE branch only: coalesce(quantity, 1), not 0.
        coalesce(ol.quantity, 1) - coalesce(ol.issued_quantity, 0)         as qty_unissued_else_basis
    from order_lines ol
    inner join orders             o   on ol.order_id  = o.order_id
    left join  items              it  on ol.plu       = it.plu
    left join  attributes         a   on it.attribute_value_group_id = a.avg_id
    left join  events             rme on ol.event_id  = rme.event_id
    left join  disbursement_detail dd on coalesce(ol.disbursement_id, 0) = dd.disbursement_id
    left join  disbursement_total dt  on coalesce(ol.disbursement_id, 0) = dt.disbursement_id
    where ol.issued_quantity < ol.quantity
),

priced as (
    select
        *,
        case
            when disbursement_id <> 0 and price_basis <> 'R' and price_basis = '$'
                then qty_unissued * coalesce(disbursement_price, 0)
            when disbursement_id <> 0 and price_basis <> 'R' and price_basis = '%'
                -- ((amount - discount) * qty) / (100 / price)  ==  (...) * price / 100
                then (amount - discount_amount) * qty_unissued * coalesce(disbursement_price, 0) / 100.0
            when disbursement_id <> 0
                then (amount - discount_amount) * qty_unissued
                     - qty_unissued * coalesce(disbursement_total_price, 0)
            else (amount - discount_amount) * qty_unissued_else_basis
        end                                                                as amt_unissued,
        -- GeneralAdmissionFlag, TOU/GAD variant (museum tickets cohort).
        case
            when matrix_code like '%TOU%'
             and disbursement_id <> 0
             and coalesce(disbursement_name, 'GEN ADM') = 'GEN ADM'
             and substr(matrix_code, 17, 3) <> 'XGA'                       then 1
            when matrix_code like '%GAD%'                                  then 1
            else 0
        end                                                                as ga_flag_tou,
        -- GeneralAdmissionFlag, MGT variant (memorial-tour-with-museum-admission
        -- cohort). No %GAD% branch in the legacy CASE for this cohort.
        case
            when matrix_code like '%MGT%'
             and disbursement_id <> 0
             and coalesce(disbursement_name, 'GEN ADM') = 'GEN ADM'
             and substr(matrix_code, 17, 3) <> 'XGA'                       then 1
            else 0
        end                                                                as ga_flag_mgt
    from base
),

-- ===================================================================== COHORTS

museum_tickets_priced as (
    -- t_fact_museum_tickets_unissued_fordate_new, first UNION leg.
    select
        'museum_tickets'                                                   as cohort,
        'priced'                                                           as leg,
        event_date_key                                                     as date_key,
        p.order_id, p.order_line_id, p.plu, p.matrix_code, p.item_filter,
        p.ga_flag_tou                                                      as ga_flag,
        p.qty_unissued,
        p.amt_unissued
    from priced p
    where (matrix_code like '%TOU%' or matrix_code like '%GAD%')
      and matrix_code not like '%CPA%'
      and matrix_code not like '%CPB%'
      and matrix_code not like '%CPC%'
),

museum_tickets_ga_zero as (
    -- Second UNION leg: the GA component of a tour ticket sold without a
    -- disbursement. Quantity counts, revenue is forced to zero, ga_flag is
    -- hard-coded 1. Deliberately overlaps the first leg's %TOU% rows — that is
    -- how the legacy UNION ALL behaves and how the GA count is credited.
    select
        'museum_tickets'                                                   as cohort,
        'ga_zero'                                                          as leg,
        event_date_key                                                     as date_key,
        p.order_id, p.order_line_id, p.plu, p.matrix_code, p.item_filter,
        1                                                                  as ga_flag,
        p.qty_unissued,
        0                                                                  as amt_unissued
    from priced p
    where matrix_code like '%TOU%'
      and matrix_code not like '%XGA%'
      and disbursement_id = 0
),

memorial_tours_priced as (
    -- t_fact_memorial_guided_tours_unissued_fordate_new, first UNION leg.
    select
        'memorial_tours'                                                   as cohort,
        'priced'                                                           as leg,
        event_date_key                                                     as date_key,
        p.order_id, p.order_line_id, p.plu, p.matrix_code, p.item_filter,
        p.ga_flag_tou                                                      as ga_flag,
        p.qty_unissued,
        p.amt_unissued
    from priced p
    where matrix_code like '%MGT%'
      and matrix_code like '%XGA%'
      and matrix_code not like '%CPA%'
      and matrix_code not like '%CPB%'
),

memorial_tours_ga_zero as (
    select
        'memorial_tours'                                                   as cohort,
        'ga_zero'                                                          as leg,
        event_date_key                                                     as date_key,
        p.order_id, p.order_line_id, p.plu, p.matrix_code, p.item_filter,
        1                                                                  as ga_flag,
        p.qty_unissued,
        0                                                                  as amt_unissued
    from priced p
    where matrix_code like '%MGT%'
      and matrix_code not like '%XGA%'
      and disbursement_id = 0
),

mem_tour_mus_admission as (
    -- t_fact_mus_tickets_mem_tour_unissued_fordate_refresh. Writes into the same
    -- legacy target table as the museum cohort, and the DPR reads it back with
    -- (account_idno like '%MGT%' and like '%XXX%'), so it is a cohort of its own
    -- here rather than a filter downstream.
    select
        'mem_tour_mus_admission'                                           as cohort,
        'priced'                                                           as leg,
        event_date_key                                                     as date_key,
        p.order_id, p.order_line_id, p.plu, p.matrix_code, p.item_filter,
        p.ga_flag_mgt                                                      as ga_flag,
        p.qty_unissued,
        p.amt_unissued
    from priced p
    where matrix_code like '%MGT%'
      and matrix_code like '%XXX%'
      and matrix_code not like '%CPA%'
      and matrix_code not like '%CPB%'
      and matrix_code not like '%CPC%'
),

ticketing_donations as (
    -- t_fact_museum_ticketing_donations_unissued. Different date basis
    -- (Orders.OpenDate, not the event) and a different, simpler amount:
    --   SUM((d.Amount) * (d.quantity - d.issuedquantity))
    -- with no discount subtraction and no disbursement Basis CASE at all.
    select
        'ticketing_donations'                                              as cohort,
        'priced'                                                           as leg,
        order_date_key                                                     as date_key,
        p.order_id, p.order_line_id, p.plu, p.matrix_code, p.item_filter,
        0                                                                  as ga_flag,
        p.qty_unissued,
        p.amount * p.qty_unissued                                          as amt_unissued
    from priced p
    where matrix_code like '%MUS%'
      and matrix_code like '%DON%'
      and p.qty_unissued > 0
),

combined as (
    select * from museum_tickets_priced
    union all select * from museum_tickets_ga_zero
    union all select * from memorial_tours_priced
    union all select * from memorial_tours_ga_zero
    union all select * from mem_tour_mus_admission
    union all select * from ticketing_donations
)

select
    cohort,
    leg,
    date_key,
    order_id,
    order_line_id,
    plu,
    matrix_code,
    item_filter,
    ga_flag,
    qty_unissued,
    amt_unissued
from combined
where date_key is not null
