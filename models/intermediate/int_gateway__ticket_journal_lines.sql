-- Silver intermediate: enriched Gateway (Galaxy) ticket journal lines
-- Co-authored with CoCo
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing
-- Grain:  one row per JnlDetails line for a ticket (jnl_code_id = 101)
--
-- Conforms the seven Galaxy tables the DPR ticket/tour/pass line items all
-- share (jnldetails + jnltickets + items + vattribute + coa +
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

{{ config(materialized='view') }}

with jnl_details as (
    select *
    from {{ ref('stg_gateway__jnldetails') }}
    where jnl_code_id = 101          -- ticket lines only
),

jnl_tickets as (
    select * from {{ ref('stg_gateway__jnltickets') }}
),

items as (
    select * from {{ ref('stg_gateway__items') }}
),

vattribute as (
    select * from {{ ref('stg_gateway__vattribute') }}
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
        {{ gateway_recognized_date('va', 'jt', 'rme') }}                     as key_date,

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
        va.itm_default_customer_id,

        -- General admission flag (attendance vs tour split)
        {{ gateway_general_admission_flag('va', 'jt', 'dd') }}              as ga_flag,

        -- Disbursement context
        jt.disbursement_id,
        dd.disbursement_name,

        -- Measures (additive)
        jd.quantity                                                         as quantity,
        jd.amount                                                           as amount,

        -- Metadata
        jd._loaded_at

    from jnl_details            jd
    inner join jnl_tickets      jt   on jd.aux_table_id = jt.jnl_detail_id
    inner join items            it   on jt.plu          = it.plu
    inner join vattribute       va   on it.attribute_value_group_id = va.avg_id
    inner join coa              c    on jd.account_id   = c.account_id
    left join disbursement      dd   on jt.disbursement_id = dd.disbursement_id
                                    and c.gl_code       = 101
                                    and c.company_id    = dd.company_id
                                    and c.category      = dd.category
                                    and c.subcategory   = dd.subcategory
    left join events            rme  on rme.event_id    = jt.event_no

    -- Exclude the external-event placeholder PLU that legacy queries always drop
    where it.plu <> 'EXTEVENTAD001'
      and (
             try_cast(va.itm_default_customer_id as number) not in (20056, 23361)
          or va.itm_default_customer_id is null
      )
)

select * from joined
where key_date is not null
