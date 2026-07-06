-- Staging model for CounterPoint POS ticket history lines (SEED_CP_PSTKTHISTLIN)
-- Co-authored with CoCo

{{ config(materialized='view') }}

with source as (
    select * from {{ source('counterpoint_seed', 'seed_cp_pstkthistlin') }}
),

staged as (
    select
        -- Primary / composite key
        bus_dat                                 as business_date,
        doc_id                                  as doc_id,
        lin_seq_no                              as line_seq_no,
        lin_guid                                as line_guid,

        -- Parent link
        link_lin_guid                           as link_line_guid,
        par_lin_guid                            as parent_line_guid,

        -- Transaction context
        event_no                                as event_no,
        str_id                                  as store_id,
        sta_id                                  as station_id,
        tkt_no                                  as ticket_no,

        -- Line type
        lin_typ                                 as line_type,

        -- Item
        item_no                                 as item_no,
        barcod                                  as barcode,
        rndm_weight_barcod                      as random_weight_barcode,
        descr                                   as description,
        cell_descr                              as cell_description,

        -- Classification
        categ_cod                               as category_code,
        subcat_cod                              as subcategory_code,
        item_vend_no                            as item_vendor_no,
        item_typ                                as item_type,
        trk_meth                                as tracking_method,

        -- Location
        stk_loc_id                              as stock_location_id,
        prc_loc_id                              as price_location_id,
        pft_ctr                                 as profit_center,

        -- Sales rep
        sls_rep                                 as sales_rep,

        -- Tax
        norm_tax_categ                          as normal_tax_category,
        tax_categ                               as tax_category,
        norm_is_txbl                            as normal_is_taxable,
        is_txbl                                 as is_taxable,
        tax_amt_alloc                           as tax_amt_allocated,
        norm_tax_amt_alloc                      as normal_tax_amt_allocated,
        is_food_stmp_elig                       as is_food_stamp_eligible,

        -- Quantity
        qty_sold                                as quantity_sold,
        qty_numer                               as quantity_numerator,
        qty_denom                               as quantity_denominator,
        qty_unit                                as quantity_unit,
        sell_unit                               as sell_unit,
        qty_ret                                 as quantity_returned,

        -- Weight
        unit_weight                             as unit_weight,
        unit_cube                               as unit_cube,
        is_weighed                              as is_weighed,
        is_man_entd_wght                        as is_manual_entered_weight,
        tare_cod                                as tare_code,
        tare_cod_idx                            as tare_code_index,
        tare_weight                             as tare_weight,

        -- Pricing
        unit_cost                               as unit_cost,
        prc_1                                   as price_1,
        calc_prc                                as calculated_price,
        reg_prc                                 as regular_price,
        prc                                     as price,
        ext_cost                                as ext_cost,
        ext_prc                                 as ext_price,
        calc_ext_prc                            as calculated_ext_price,
        gross_ext_prc                           as gross_ext_price,
        gross_disp_ext_prc                      as gross_display_ext_price,
        disp_ext_prc                            as display_ext_price,
        unit_retl_val                           as unit_retail_value,
        unit_retl_at_post                       as unit_retail_at_post,
        tot_cost_corr                           as total_cost_correction,
        presumed_cost                           as presumed_cost,
        std_cost                                as standard_cost,
        cost_entd                               as cost_entered,

        -- Price override
        has_prc_ovrd                            as has_price_override,
        prc_ovrd_reas                           as price_override_reason,
        usr_entd_prc                            as user_entered_price,

        -- Mix/match
        mix_match_cod                           as mix_match_code,
        mix_match_contrib                       as mix_match_contribution,
        mix_match_prc_based_on                  as mix_match_price_based_on,

        -- Dimensions
        is_single_cell                          as is_single_cell,
        dim_1_upr                               as dimension_1,
        dim_2_upr                               as dimension_2,
        dim_3_upr                               as dimension_3,

        -- Serial
        ser_no                                  as serial_no,
        no_of_sers_entd                         as no_of_serials_entered,

        -- Returns
        ret_reas                                as return_reason,
        is_val_ret                              as is_value_return,
        is_scrap_ret_lin                        as is_scrap_return_line,

        -- Flags
        is_discntbl                             as is_discountable,
        is_kit_par                              as is_kit_parent,

        -- Gift registry
        gft_rgstry_id                           as gift_registry_id,

        -- Ecommerce
        ec_seq_no                               as ecommerce_seq_no,

        -- Reference
        ref                                     as reference

    from source
)

select * from staged
