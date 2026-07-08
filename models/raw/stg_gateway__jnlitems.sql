-- Staging model for Gateway Galaxy journal items (SEED_GATE_JNLITEMS)
-- Co-authored with CoCo

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_jnlitems') }}
),

staged as (
    select
        -- Primary key
        jnlitemid                               as jnl_item_id,

        -- Parent reference
        jnltranid                               as jnl_tran_id,
        tranitemno                              as tran_item_no,

        -- Product
        -- trim: keep aligned with stg_gateway__items.plu (CHAR(20) padded in source)
        trim(plu)                               as plu,
        fkeyno                                  as function_key_no,
        productno                               as product_no,

        -- Pricing
        unitprice                               as unit_price,
        costamt                                 as cost_amt,
        tax                                     as tax,
        taxflags                                as tax_flags,
        taxmethods                              as tax_methods,
        taxtableid                              as tax_table_id,
        commission                              as commission,

        -- Discounts
        discno                                  as discount_no,
        discamt                                 as discount_amt,
        discoccur                               as discount_occurrences,
        coupons                                 as coupon_count,

        -- Upsell
        upsellstatus                            as upsell_status,
        upsellplu                               as upsell_plu,
        upsellpricedifference                   as upsell_price_difference,
        upselltype                              as upsell_type,
        upselluserid                            as upsell_user_id,
        upsellsaleschanneltype                  as upsell_sales_channel_type,

        -- Loyalty / gift aid
        loyaltypoints                           as loyalty_points,
        redeemedvalue                           as redeemed_value,
        giftaidtype                             as gift_aid_type,

        -- Sales program
        salesprogramid                          as sales_program_id,
        supervisorid                            as supervisor_id,
        pricescheduleid                         as price_schedule_id,
        transmodifierid                         as trans_modifier_id,

        -- Package
        pkginstancedetailid                     as pkg_instance_detail_id,
        packageprintsequence                    as package_print_sequence,

        -- FOP
        fopnumber                               as fop_number,
        fopitemid                               as fop_item_id,

        -- Audit
        recordversion                           as record_version,
        lastupdatedby                           as last_updated_by,

        -- Dates
        try_to_timestamp(lastupdate)            as last_updated_at,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
qualify row_number() over (partition by jnl_item_id order by _loaded_at desc) = 1