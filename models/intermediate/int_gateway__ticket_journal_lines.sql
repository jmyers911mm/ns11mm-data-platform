-- Silver intermediate: enriched Gateway (Galaxy) ticket journal lines
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing
-- Grain:  one row per JnlDetails line for a ticket (jnl_code_id = 101)
--
-- Conforms the eight Galaxy tables the DPR ticket/tour/pass line items all
-- share (jnldetails + jnltickets + jnlheaders + items + vattribute + coa +
-- disbursementdetails + rmevents) into a single enriched line-grain fact.
-- Downstream int_dpr__* models filter this by matrix code / PLU / ga_flag
-- rather than re-joining the base tables, which is where the legacy Pentaho
-- estate accumulated its duplication.
--
-- Legacy lineage: the JnlDetails.JnlcodeID = 101 join pattern shared by
-- t_reporting_ticket_revenue_new, t_reporting_tickets_sold_issued_new,
-- t_reporting_mus_guided_tours_revenue, t_reporting_mem_guided_tours_revenue,
-- t_fact_museum_tickets_issued_fordate_new, and the tours family.
--
-- ADR-001: reads only from stg_ (RAW is upstream and immutable).
-- ADR-004: all business logic lives here, not in Power BI.
-- Attribute (matrix_code) lookup comes from the shared int_gateway__item_attributes.
-- Placeholder-PLU and excluded-customer lists are seed-driven
-- (seed_gateway_excluded_plu / seed_gateway_excluded_customer).
--
-- 8.1.0 JOIN-CARDINALITY FIX: coa and attributes were INNER joins. Every legacy
-- extract that builds this grain uses LEFT OUTER JOIN dbo.COA and
-- LEFT OUTER JOIN report.vAttribute with ISNULL(vA.rItmMatrixCode,'')
-- (t_fact_museum_tickets_issued_fordate_new, t_fact_museum_citypass,
-- t_fact_museum_citypass_booklets, t_reporting_* family). Inner-joining them
-- silently dropped every ticket line whose account has no COA row and every
-- line whose item has no attribute-value group -- and those lines feed
-- admissions, tours AND fees, so the loss was invisible three models
-- downstream. Both are now LEFT joins with the legacy coalesce. jnl_tickets
-- and items stay INNER: legacy left-joins them too, but its WHERE clause
-- (Items.PLU <> 'EXTEVENTAD001' AND matrix LIKE ...) drops the unmatched rows
-- again, so inner is equivalent there and does not need to change.
--
-- 8.6.0 additions (ADR-005 GATED — see DECISION_MEMO.md):
--  * customer_id (JnlTickets.CustomerID). This is the TRANSACTION customer and
--    is a DIFFERENT column from va.itm_default_customer_id, which is the
--    item-master default customer already used by seed_gateway_excluded_customer.
--    Legacy proves they are distinct: t_fact_museum_tickets_issued_fordate_new
--    filters `vA.rItmDefaultCustomerID NOT IN (20056, 23361)` in its WHERE and
--    separately carries `JNLTickets.CustomerID` as a column, which the reporting
--    layer then splits on (`f.customer_id not in (...)` for ticket revenue,
--    `f.customer_id in (...)` for pass revenue). Needed for the reseller split
--    in int_dpr__admissions.
--  * tran_date_key (JnlHeaders.TranDate). Item-grain measures recognize on the
--    transaction date, not on the ticket recognized date. t_fact_service_fees_new
--    keys its museum service fees off JnlHeaders.TranDate for BOTH the item
--    lines and the ticket lines it reads, so the ticket-line half of that
--    measure needs the transaction date available at this grain.
--  * event_type_id, and the EventTypeID <> 56 exclusion. Legacy
--    (t_fact_museum_tickets_issued_fordate_new, t_fact_museum_citypass)
--    restricts RMEvents to EventTypeID <> 56. DIVERGENCE, deliberate: legacy
--    INNER joins its event set, which would also drop every line whose event
--    does not resolve. rme.start_at is NULL for ~95% of basis-182 lines in the
--    current extract (see gateway_recognized_date), so an inner join here would
--    delete most of the fact. The exclusion is therefore applied only to rows
--    whose event type is KNOWN to be 56; unresolved events are kept. Revisit
--    when the rmevents extract is complete.

-- Materialized as a TABLE, not a view: this model runs 8 joins and is consumed
-- by 3 downstream models (admissions, tour_revenue, fees) each run — a view
-- would re-execute all 8 joins 3x per build. Build once, read 3x. transient +
-- copy_grants are inherited from the intermediate defaults in dbt_project.yml.
{{ config(materialized='table') }}

with jnl_details as (
    select *
    from {{ ref('stg_gateway__jnldetails') }}
    where jnl_code_id = 101          -- ticket lines only
),

jnl_tickets as (
    select * from {{ ref('stg_gateway__jnltickets') }}
),

jnl_headers as (
    select * from {{ ref('stg_gateway__jnlheaders') }}
),

items as (
    select * from {{ ref('stg_gateway__items') }}
),

attributes as (
    select * from {{ ref('int_gateway__item_attributes') }}
),

coa as (
    select * from {{ ref('stg_gateway__coa') }}
),

disbursement as (
    select * from {{ ref('stg_gateway__disbursementdetails') }}
),

events as (
    select * from {{ ref('stg_gateway__rmevents') }}
),

joined as (
    select
        -- Keys
        jd.jnl_detail_id,
        jd.jnl_tran_id,
        jt.order_no,
        jt.visual_id,
        jt.event_no,

        -- Recognized reporting date (event / ticket / sold+14 depending on basis)
        {{ gateway_recognized_date('va', 'jt', 'rme') }}                     as date_key,

        -- Transaction (fiscal posting) date. Distinct from date_key: item-grain
        -- measures such as service fees recognize on JnlHeaders.TranDate, not on
        -- the ticket recognize basis. Legacy: t_fact_service_fees_new.
        cast(jh.tran_date as date)                                           as tran_date_key,

        -- Product classification
        trim(it.plu)                                                        as plu,
        it.item_filter,
        it.description                                                      as item_description,
        it.kind                                                             as item_kind,
        it.cost                                                             as item_cost,
        it.price                                                            as item_price,
        coalesce(va.itm_matrix_code, '')                                    as matrix_code,
        substr(coalesce(va.itm_matrix_code, ''), 1, 3)                      as visit_type,
        va.itm_recognize_basis_id,
        -- Item-master DEFAULT customer (vAttribute.rItmDefaultCustomerID). Drives
        -- the seed_gateway_excluded_customer exclusion below. NOT the same thing
        -- as customer_id.
        va.itm_default_customer_id,
        -- TRANSACTION customer (JnlTickets.CustomerID). Drives the reseller /
        -- pass-revenue split in int_dpr__admissions.
        jt.customer_id,

        -- General admission flag (attendance vs tour split)
        {{ gateway_general_admission_flag('va', 'jt', 'dd') }}              as ga_flag,

        -- Disbursement context
        jt.disbursement_id,
        dd.disbursement_name,

        -- Event context (legacy excludes EventTypeID 56 from the ticket cohorts)
        rme.event_type_id,

        -- Measures (additive)
        jd.quantity                                                         as quantity,
        jd.amount                                                           as amount,

        -- Metadata
        jd._loaded_at

    from jnl_details            jd
    inner join jnl_tickets      jt   on jd.aux_table_id = jt.jnl_detail_id
    inner join jnl_headers      jh   on jd.jnl_tran_id  = jh.jnl_tran_id
    inner join items            it   on jt.plu          = it.plu
    -- LEFT (was INNER): legacy `left outer join report.vAttribute vA on
    -- Items.AttributeValueGroupID = vA.avgID`. Items with no attribute group
    -- keep their line; matrix_code coalesces to '' exactly as ISNULL does.
    left join attributes        va   on it.attribute_value_group_id = va.avg_id
    -- LEFT (was INNER): legacy `left outer join dbo.COA on
    -- jnldetails.AccountID = coa.AccountID`. COA is only a bridge to the
    -- disbursement lookup, so a missing COA row must not remove the line.
    left join coa               c    on jd.account_id   = c.account_id
    left join disbursement      dd   on jt.disbursement_id = dd.disbursement_id
                                    and c.gl_code       = 101
                                    and c.company_id    = dd.company_id
                                    and c.category      = dd.category
                                    and c.subcategory   = dd.subcategory
    left join events            rme  on rme.event_id    = jt.event_no

    -- Exclusions (seed-driven). Placeholder/external-event PLU always dropped;
    -- internal/default customers excluded (NULL customer is kept, as before --
    -- legacy: `(vA.rItmDefaultCustomerID NOT IN (20056, 23361)) OR
    -- (vA.rItmDefaultCustomerID IS NULL)`, which the left join now also
    -- satisfies for items with no attribute row at all).
    where it.plu not in (select plu from {{ ref('seed_gateway_excluded_plu') }})
      and not exists (
            select 1
            from {{ ref('seed_gateway_excluded_customer') }} ec
            where ec.customer_id = try_cast(va.itm_default_customer_id as number)
      )
      -- Legacy `AND EventTypeID <> 56` (t_fact_museum_tickets_issued_fordate_new
      -- @TOTAL_EVENTS; t_fact_museum_citypass WHERE clause). Applied only where
      -- the event type is known -- see the divergence note in the header.
      -- event_type_id lands as NUMBER in RAW, and Snowflake's TRY_CAST accepts
      -- only a string input, so it is cast to varchar first. That keeps the
      -- guard working whether the extract lands the column numeric or text.
      and coalesce(try_cast(rme.event_type_id::varchar as number), -1) <> 56
)

select * from joined
where date_key is not null