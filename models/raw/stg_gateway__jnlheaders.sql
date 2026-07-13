-- Bronze staging: Gateway (Galaxy) journal headers
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (DPR base)
-- Grain:  one row per jnl_tran_id (dedup: latest _loaded_at wins)
--
-- Conforms seed_gate_jnlheaders, the transaction header (jnl_tran_id) parent for
-- the jnldetails / jnltickets / jnlitems line tables. Renames only.
--
-- ADR-001: rename/recast only, no business logic (that lands in the int_ layer).

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_jnlheaders') }}
),

staged as (
    select
        -- Primary key
        jnltranid                               as jnl_tran_id,
        jnlheaderguid                           as jnl_header_guid,

        -- Transaction context
        nodeno                                  as node_no,
        tranno                                  as tran_no,
        seqno                                   as seq_no,
        receiptno                               as receipt_no,
        shiftno                                 as shift_no,

        -- Classification
        jnlcode                                 as jnl_code,
        trankind                                as tran_kind,
        companyid                               as company_id,

        -- Personnel
        userid                                  as user_id,
        agency                                  as agency_id,
        supervisorid                            as supervisor_id,

        -- Adjustment
        adjustment                              as is_adjustment,
        adjustmentuser                          as adjustment_user_id,
        adjustmenttime                          as adjustment_time,
        sareason                                as sa_reason,

        -- Status
        posted                                  as posted,
        postedtodb                              as posted_to_db,
        reference                               as reference,

        -- Financials
        transsalestotal                         as trans_sales_total,
        loyaltybonuspoints                      as loyalty_bonus_points,
        transupsellcancelled                    as tran_upsell_cancelled,

        -- Misc
        translationlanguageid                   as translation_language_id,
        recordversion                           as record_version,
        lastupdatedby                           as last_updated_by,

        -- Dates
        try_to_timestamp(fiscaldate)            as fiscal_date,
        try_to_timestamp(trandate)              as tran_date,
        try_to_timestamp(transstartdatetime)    as trans_start_at,
        try_to_timestamp(transenddatetime)      as trans_end_at,
        try_to_timestamp(lastupdate)            as last_updated_at,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
qualify row_number() over (partition by jnl_tran_id order by _loaded_at desc) = 1
