-- Silver intermediate: enriched Gateway (Galaxy) item journal lines
-- ---------------------------------------------------------------------------
-- Domain: revenue (audio guides, service fees, ticketing donations)
-- Grain:  one row per JnlDetails line linked to a JnlItem
--         (jnl_code_id in 102, 103, 104)
--
-- The audio-guide, service-fee and ticketing-donation DPR line items pull
-- from JnlItems rather than JnlTickets. Legacy lineage:
--   t_fact_museum_audio_new, t_fact_memorial_audio_new,
--   t_fact_service_fees_new, t_fact_museum_ticketing_donations_issued.
--
-- ADR-001 / ADR-004 as per int_gateway__ticket_journal_lines.
-- Attribute (matrix_code) lookup comes from the shared int_gateway__item_attributes.

-- Materialized as a TABLE, not a view: 4 joins consumed by 2 downstream models
-- (fees_and_services, donations) each run — a view re-runs the joins 2x per
-- build. transient + copy_grants inherited from the intermediate defaults.
{{ config(materialized='table') }}

with jnl_details as (
    select *
    from {{ ref('stg_gateway__jnldetails') }}
    where jnl_code_id in (102, 103, 104)   -- item lines
),

jnl_items as (
    select * from {{ ref('stg_gateway__jnlitems') }}
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

joined as (
    select
        -- Keys
        jd.jnl_detail_id,
        jd.jnl_tran_id,
        ji.jnl_item_id,

        -- Reporting date: item lines recognize on the transaction (fiscal) date.
        -- Legacy used JnlHeaders.TranDate (fiscalDate for the single known
        -- correction JnlTranID 12383495 on ticketing donations).
        cast(
            case
                when jh.jnl_tran_id = 12383495 then jh.fiscal_date
                else jh.tran_date
            end as date
        )                                                                   as date_key,

        -- Product classification
        it.plu,
        it.item_filter,
        it.description                                                      as item_description,
        it.kind                                                             as item_kind,
        it.cost                                                             as item_cost,
        it.price                                                            as item_price,
        coalesce(va.itm_matrix_code, '')                                    as matrix_code,

        -- Measures (additive)
        jd.quantity                                                         as quantity,
        jd.amount                                                           as amount,
        ji.tax                                                              as tax,

        -- Metadata
        jd._loaded_at

    from jnl_details        jd
    inner join jnl_items    ji  on jd.aux_table_id = ji.jnl_item_id
    inner join jnl_headers  jh  on jd.jnl_tran_id  = jh.jnl_tran_id
    inner join items        it  on ji.plu          = it.plu
    left join attributes    va  on it.attribute_value_group_id = va.avg_id
)

select * from joined
where date_key is not null
