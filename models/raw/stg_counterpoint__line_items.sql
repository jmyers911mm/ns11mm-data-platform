/*
  stg_counterpoint__line_items
  Source: RAW.RAW_COUNTERPOINT_LINEITEMS (PS_TKT_HIST_LIN)
  Grain: one row per line item (DOC_ID + LIN_SEQ_NO)
  STATUS: Awaiting RAW data connection. Column names confirmed from CP_schema.xlsx.

  Key fields:
    DOC_ID / LIN_SEQ_NO — composite PK
    ITEM_NO             — item number (joins to IM_ITEM)
    CATEG_COD           — category code for product grouping
    QTY_SOLD            — quantity sold (negative for returns)
    PRC                 — actual selling price per unit
    EXT_PRC             — extended price (QTY * PRC after discounts)
    GROSS_EXT_PRC       — extended price before discounts
    UNIT_COST           — cost of goods
    LIN_TYP             — S=Sale, R=Return, etc.
*/

{{ config(materialized='view') }}

with source as (
    select _raw_data from {{ source('counterpoint', 'raw_counterpoint_lineitems') }}
),

staged as (
    select
        -- Keys
        _raw_data:DOC_ID::bigint                        as doc_id,
        _raw_data:LIN_SEQ_NO::int                       as lin_seq_no,
        _raw_data:STR_ID::varchar                       as str_id,
        _raw_data:STA_ID::varchar                       as sta_id,
        _raw_data:TKT_NO::varchar                       as tkt_no,
        _raw_data:EVENT_NO::varchar                     as event_no,

        -- Date
        _raw_data:BUS_DAT::date                         as business_date,

        -- Item identification
        _raw_data:ITEM_NO::varchar                      as item_no,
        _raw_data:BARCOD::varchar                       as barcode,
        _raw_data:DESCR::varchar                        as item_descr,

        -- Product classification
        _raw_data:CATEG_COD::varchar                    as categ_cod,
        _raw_data:SUBCAT_COD::varchar                   as subcat_cod,
        _raw_data:ITEM_TYP::varchar                     as item_typ,
        _raw_data:ITEM_VEND_NO::varchar                 as item_vend_no,

        -- Location
        _raw_data:STK_LOC_ID::varchar                   as stk_loc_id,
        _raw_data:PFT_CTR::varchar                      as pft_ctr,

        -- Line classification
        _raw_data:LIN_TYP::varchar                      as lin_typ,
        _raw_data:RET_REAS::varchar                     as return_reason,
        _raw_data:SLS_REP::varchar                      as sls_rep,
        _raw_data:REF::varchar                          as reference,

        -- Quantity
        _raw_data:QTY_SOLD::decimal(18,4)               as qty_sold,
        _raw_data:QTY_UNIT::varchar                     as qty_unit,
        _raw_data:SELL_UNIT::varchar                    as sell_unit,

        -- Pricing
        _raw_data:PRC_1::decimal(18,4)                  as prc_1,          -- base price level 1
        _raw_data:REG_PRC::decimal(18,4)                as reg_prc,         -- regular price
        _raw_data:CALC_PRC::decimal(18,4)               as calc_prc,        -- calculated price
        _raw_data:PRC::decimal(18,4)                    as unit_prc,        -- actual selling price
        _raw_data:GROSS_EXT_PRC::decimal(18,4)          as gross_ext_prc,   -- extended before disc
        _raw_data:EXT_PRC::decimal(18,4)                as ext_prc,         -- extended after disc
        _raw_data:DISP_EXT_PRC::decimal(18,4)           as disp_ext_prc,    -- displayed extended price
        _raw_data:CALC_EXT_PRC::decimal(18,4)           as calc_ext_prc,

        -- Cost
        _raw_data:UNIT_COST::decimal(18,4)              as unit_cost,
        _raw_data:EXT_COST::decimal(18,4)               as ext_cost,

        -- Tax
        _raw_data:IS_TXBL::varchar                      as is_taxable,
        _raw_data:TAX_AMT_ALLOC::decimal(18,4)          as tax_amt_alloc,
        _raw_data:TAX_CATEG::varchar                    as tax_categ,

        -- Discount flags
        _raw_data:IS_DISCNTBL::varchar                  as is_discountable,
        _raw_data:HAS_PRC_OVRD::varchar                 as has_price_override,
        _raw_data:MIX_MATCH_COD::varchar                as mix_match_cod,

        -- Dimensions (grid items like size/color)
        _raw_data:CELL_DESCR::varchar                   as cell_descr,
        _raw_data:DIM_1_UPR::varchar                    as dim_1,
        _raw_data:DIM_2_UPR::varchar                    as dim_2,
        _raw_data:DIM_3_UPR::varchar                    as dim_3,

        -- Metadata
        _extracted_at

    from source
),

with_derived as (
    select
        {{ generate_hashdiff(['doc_id', 'lin_seq_no', 'str_id']) }}
                                                        as line_hashdiff,
        *,
        -- Derived
        gross_ext_prc - ext_prc                         as line_disc_amt,
        case when lin_typ = 'R' then true else false end as is_return,
        case when qty_sold < 0 then true else false end  as is_negative_qty
    from staged
)

select * from with_derived