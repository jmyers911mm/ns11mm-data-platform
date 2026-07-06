-- Staging model for CounterPoint ticket history view - lines (SEED_CP_VITKTHISTLIN)
-- Co-authored with CoCo

{{ config(materialized='view') }}

with source as (
    select * from {{ source('counterpoint_seed', 'seed_cp_vitkthistlin') }}
),

staged as (
    select
        -- Primary / composite key
        bus_dat                                 as business_date,
        doc_id                                  as doc_id,
        lin_seq_no                              as line_seq_no,
        seq_no                                  as seq_no,
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
        ref                                     as reference,
        sls_rep                                 as sales_rep,

        -- Item
        item_no                                 as item_no,
        barcod                                  as barcode,
        rndm_weight_barcod                      as random_weight_barcode,
        descr                                   as description,
        cell_descr                              as cell_description,

        -- Classification
        categ_cod                               as category_code,
        subcat_cod                              as subcategory_code,
        categ_subcat                            as category_subcategory,
        item_vend_no                            as item_vendor_no,
        item_typ                                as item_type,
        trk_meth                                as tracking_method,

        -- Location
        stk_loc_id                              as stock_location_id,
        prc_loc_id                              as price_location_id,
        pft_ctr                                 as profit_center,

        -- Quantity
        qty_sold                                as quantity_sold,
        qty_numer                               as quantity_numerator,
        qty_denom                               as quantity_denominator,
        qty_unit                                as quantity_unit,
        sell_unit                               as sell_unit,
        qty_sold_stk_unit                       as quantity_sold_stock_unit,
        qty_ret                                 as quantity_returned,

        -- Weight
        unit_weight                             as unit_weight,
        unit_cube                               as unit_cube,
        ext_weight                              as ext_weight,
        ext_cube                                as ext_cube,
        is_weighed                              as is_weighed,
        is_man_entd_wght                        as is_manual_entered_weight,
        tare_cod                                as tare_code,
        tare_weight                             as tare_weight,
        tare_cod_idx                            as tare_code_index,

        -- Tax
        norm_is_txbl                            as normal_is_taxable,
        is_txbl                                 as is_taxable,
        has_tax_ovrd                            as has_tax_override,
        norm_tax_categ                          as normal_tax_category,
        tax_categ                               as tax_category,
        tax_categ_chngd                         as tax_category_changed,
        tax_amt_alloc                           as tax_amt_allocated,
        norm_tax_amt_alloc                      as normal_tax_amt_allocated,
        is_food_stmp_elig                       as is_food_stamp_eligible,
        is_food_stmp_lin                        as is_food_stamp_line,

        -- Pricing
        prc_1                                   as price_1,
        reg_prc                                 as regular_price,
        calc_prc                                as calculated_price,
        prc                                     as price,
        presumed_cost                           as presumed_cost,
        cost_entd                               as cost_entered,
        cost                                    as cost,
        std_cost                                as standard_cost,
        use_cost_entd                           as use_cost_entered,
        usr_entd_prc                            as user_entered_price,
        has_prc_ovrd                            as has_price_override,
        prc_ovrd_reas                           as price_override_reason,
        tot_cost_corr                           as total_cost_correction,

        -- Extended pricing
        ext_cost                                as ext_cost,
        est_ext_cost                            as est_ext_cost,
        ext_prc                                 as ext_price,
        ext_calc_prc                            as ext_calculated_price,
        gross_ext_prc                           as gross_ext_price,
        discntd_ext_prc                         as discounted_ext_price,
        calc_ext_prc                            as calculated_ext_price,
        gross_disp_ext_prc                      as gross_display_ext_price,
        discntd_disp_ext_prc                    as discounted_display_ext_price,
        disp_ext_prc                            as display_ext_price,
        comp_ext_cost                           as comp_ext_cost,
        comp_ext_prc                            as comp_ext_price,

        -- Discount analysis
        prc_1_disc                              as price_1_discount,
        prc_1_disc_pct                          as price_1_discount_pct,
        unit_retl_val                           as unit_retail_value,
        unit_retl_val_disc                      as unit_retail_value_discount,
        unit_retl_val_disc_pct                  as unit_retail_value_discount_pct,
        unit_retl_at_post                       as unit_retail_at_post,
        unit_retl_at_post_disc                  as unit_retail_at_post_discount,
        unit_retl_at_post_disc_pct              as unit_retail_at_post_discount_pct,
        reg_prc_disc                            as regular_price_discount,
        reg_prc_disc_pct                        as regular_price_discount_pct,
        calc_prc_disc                           as calculated_price_discount,
        calc_prc_disc_pct                       as calculated_price_discount_pct,
        lin_disc_amt                            as line_discount_amt,
        hdr_disc_amt                            as header_discount_amt,
        grs_pft                                 as gross_profit,

        -- Mix/match
        mix_match_cod                           as mix_match_code,
        mix_match_contrib                       as mix_match_contribution,
        mix_match_prc_based_on                  as mix_match_price_based_on,

        -- Loyalty
        lin_loy_pts_earnd                       as line_loyalty_pts_earned,
        loy_pgm_rdm_elig                        as loyalty_program_redeem_eligible,
        loy_pgm_amt_pd_with_pts                 as loyalty_amt_paid_with_pts,
        loy_pt_earn_rul_descr                   as loyalty_earn_rule_description,
        loy_pt_earn_rul_seq_no                  as loyalty_earn_rule_seq_no,
        loy_pt_rdm_rul_descr                    as loyalty_redeem_rule_description,
        loy_pt_rdm_rul_seq_no                   as loyalty_redeem_rule_seq_no,

        -- Dimensions
        is_single_cell                          as is_single_cell,
        dim_1_upr                               as dimension_1,
        dim_2_upr                               as dimension_2,
        dim_3_upr                               as dimension_3,

        -- Serial
        ser_no                                  as serial_no,
        ser_descr                               as serial_description,
        no_of_sers_entd                         as no_of_serials_entered,

        -- Returns
        ret_reas                                as return_reason,
        is_val_ret                              as is_value_return,
        is_scrap_ret_lin                        as is_scrap_return_line,

        -- Flags
        is_discntbl                             as is_discountable,
        is_kit_par                              as is_kit_parent,

        -- Kit components
        par_item_no                             as parent_item_no,
        kit_comp_qty                            as kit_component_qty,
        kit_comp_qty_unit_flg                   as kit_component_qty_unit_flag,
        kit_comp_upcharge                       as kit_component_upcharge,
        kit_comp_item_no                        as kit_component_item_no,
        kit_comp_dim_1_upr                      as kit_component_dim_1,
        kit_comp_dim_2_upr                      as kit_component_dim_2,
        kit_comp_dim_3_upr                      as kit_component_dim_3,
        kit_subs_typ                            as kit_substitution_type,
        kit_prc_adj_typ                         as kit_price_adj_type,
        kit_adj_prc_lvl                         as kit_adj_price_level,

        -- Gift registry / ecommerce
        gft_rgstry_id                           as gift_registry_id,
        ec_seq_no                               as ecommerce_seq_no,

        -- Purchase order
        po_preq_no                              as po_prereq_no,
        po_ord_no                               as po_order_no,
        po_lin_seq_no                           as po_line_seq_no,
        po_recvr_no                             as po_receiver_no,
        po_recvr_lin_seq_no                     as po_receiver_line_seq_no,
        po_qty_expectd                          as po_qty_expected,
        po_tot_qty_recvd                        as po_total_qty_received,
        po_recvr_cnt                            as po_receiver_count,
        po_ord_descr                            as po_order_description,
        po_recv_stat                            as po_receive_status,

        -- Prompts
        prompt_no_1                             as prompt_no_1,
        prompt_cod_1                            as prompt_code_1,
        prompt_alpha_1                          as prompt_alpha_1,
        prompt_dat_1                            as prompt_date_1,
        prompt_1_str                            as prompt_1_string,
        prompt_no_2                             as prompt_no_2,
        prompt_cod_2                            as prompt_code_2,
        prompt_alpha_2                          as prompt_alpha_2,
        prompt_dat_2                            as prompt_date_2,
        prompt_2_str                            as prompt_2_string,
        prompt_no_3                             as prompt_no_3,
        prompt_cod_3                            as prompt_code_3,
        prompt_alpha_3                          as prompt_alpha_3,
        prompt_dat_3                            as prompt_date_3,
        prompt_3_str                            as prompt_3_string,

        -- Extended keys
        bus_dat_ext                             as business_date_ext,
        doc_id_ext                              as doc_id_ext,
        lin_seq_no_ext                          as line_seq_no_ext,

        -- Dates
        post_dat                                as post_date,
        try_to_timestamp(tkt_dat)               as ticket_date

    from source
)

select * from staged
