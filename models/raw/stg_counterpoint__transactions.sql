/*
  stg_counterpoint__transactions
  Source: RAW.RAW_COUNTERPOINT_TRANSACTIONS (PS_TKT_HIST)
  Grain: one row per ticket/transaction (DOC_ID)
  STATUS: Awaiting RAW data connection. Column names confirmed from CP_schema.xlsx.

  Key fields:
    DOC_ID      — unique transaction identifier (bigint, use as surrogate key)
    TKT_NO      — ticket number (human-readable, not unique across stores)
    STR_ID      — store identifier (joins to PS_STR)
    STA_ID      — station/register identifier (joins to PS_STA)
    BUS_DAT     — business date (smalldatetime — use this, not TKT_DT, for reporting)
    TKT_DT      — wall-clock transaction timestamp
    CUST_NO     — customer number (joins to AR_CUST; null for anonymous)
    TKT_TYP     — transaction type (S=Sale, R=Return, etc.)
    TOT         — transaction total (gross)
    SUB_TOT     — subtotal before tax
    TAX_AMT     — tax amount
    TOT_HDR_DISC / TOT_LIN_DISC — header and line discounts
    TOT_TND     — total tendered
    TOT_CHNG    — change given
*/

{{ config(materialized='view') }}

with source as (
    select _raw_data from {{ source('counterpoint', 'raw_counterpoint_transactions') }}
),

staged as (
    select
        -- Keys
        _raw_data:DOC_ID::bigint                        as doc_id,
        _raw_data:TKT_NO::varchar                       as tkt_no,
        _raw_data:STR_ID::varchar                       as str_id,
        _raw_data:STA_ID::varchar                       as sta_id,
        _raw_data:EVENT_NO::varchar                     as event_no,
        _raw_data:DRW_ID::varchar                       as drw_id,
        _raw_data:USR_ID::varchar                       as usr_id,

        -- Dates
        _raw_data:BUS_DAT::date                         as business_date,
        _raw_data:TKT_DT::timestamp_ntz                 as transaction_at,

        -- Customer
        _raw_data:CUST_NO::varchar                      as cust_no,

        -- Transaction classification
        _raw_data:TKT_TYP::varchar                      as tkt_typ,

        -- Line counts
        _raw_data:LINS::int                             as total_lines,
        _raw_data:SAL_LINS::int                         as sale_lines,
        _raw_data:RET_LINS::int                         as return_lines,

        -- Amounts
        _raw_data:SUB_TOT::decimal(18,4)                as sub_total,
        _raw_data:TOT_LIN_DISC::decimal(18,4)           as tot_line_disc,
        _raw_data:TOT_HDR_DISC::decimal(18,4)           as tot_header_disc,
        _raw_data:TOT_GFC_AMT::decimal(18,4)            as tot_gift_card_amt,
        _raw_data:TOT_SVC_AMT::decimal(18,4)            as tot_service_amt,
        _raw_data:TOT_MISC::decimal(18,4)               as tot_misc_chrg,
        _raw_data:NORM_TAX_AMT::decimal(18,4)           as normal_tax_amt,
        _raw_data:TAX_AMT::decimal(18,4)                as tax_amt,
        _raw_data:TOT::decimal(18,4)                    as total_amt,
        _raw_data:TOT_TND::decimal(18,4)                as total_tendered,
        _raw_data:TOT_CHNG::decimal(18,4)               as total_change,
        _raw_data:TOT_TIP_AMT::decimal(18,4)            as total_tip_amt,
        _raw_data:TOT_EXT_COST::decimal(18,4)           as total_ext_cost,

        -- Tax details
        _raw_data:TAX_COD::varchar                      as tax_cod,
        _raw_data:TAX_EXEMPT_NO::varchar                as tax_exempt_no,

        -- Misc flags
        _raw_data:REF::varchar                          as reference,
        _raw_data:IS_OFFLINE::boolean                   as is_offline,
        _raw_data:SLS_REP::varchar                      as sls_rep,

        -- Metadata
        _extracted_at

    from source
)

select
    {{ generate_hashdiff(['doc_id', 'tkt_no', 'str_id', 'business_date']) }}
                                                        as transaction_hashdiff,
    *
from staged