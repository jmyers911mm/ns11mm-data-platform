-- Staging model for CounterPoint item master (SEED_CP_IMITEM)
-- Co-authored with CoCo

{{ config(materialized='view') }}

with source as (
    select * from {{ source('counterpoint_seed', 'seed_cp_imitem') }}
),

staged as (
    select
        -- Primary key
        item_no                                 as item_no,

        -- Descriptions
        descr                                   as description,
        long_descr                              as long_description,
        short_descr                             as short_description,
        addl_descr_1                            as addl_description_1,
        addl_descr_2                            as addl_description_2,
        addl_descr_3                            as addl_description_3,

        -- Classification
        item_typ                                as item_type,
        categ_cod                               as category_code,
        subcat_cod                              as subcategory_code,
        categ_subcat                            as category_subcategory,
        acct_cod                                as account_code,
        lbl_cod                                 as label_code,
        trk_meth                                as tracking_method,
        stat                                    as status,
        dim_cod                                 as dimension_code,
        dim_cod_label                           as dimension_code_label,
        dim_count                               as dimension_count,

        -- Attributes
        attr_cod_1                              as attribute_code_1,
        attr_cod_2                              as attribute_code_2,
        attr_cod_3                              as attribute_code_3,
        attr_cod_4                              as attribute_code_4,
        attr_cod_5                              as attribute_code_5,
        attr_cod_6                              as attribute_code_6,

        -- Pricing
        prc_1                                   as price_1,
        reg_prc                                 as regular_price,
        lst_cost                                as last_cost,
        dflt_cost_of_sls_pct                    as default_cost_of_sales_pct,
        prc_decs                                as price_decimals,

        -- Preferred unit
        pref_unit                               as preferred_unit,
        pref_unit_nam                           as preferred_unit_name,
        pref_unit_prc_1                         as preferred_unit_price_1,
        pref_unit_reg_prc                       as preferred_unit_reg_price,
        pref_unit_numer                         as preferred_unit_numerator,
        pref_unit_denom                         as preferred_unit_denominator,
        pref_unit_weight                        as preferred_unit_weight,
        pref_unit_cube                          as preferred_unit_cube,

        -- Stock unit / weight
        stk_unit                                as stock_unit,
        qty_decs                                as quantity_decimals,
        weight                                  as weight,
        cube                                    as cube,
        tare_cod                                as tare_code,

        -- Vendor
        item_vend_no                            as item_vendor_no,
        vend_item_no                            as vendor_item_no,

        -- Barcode
        barcod                                  as barcode,
        barcod_3_of_9                           as barcode_3_of_9,
        cell_barcod_pre                         as cell_barcode_prefix,
        nxt_cell_barcod_no                      as next_cell_barcode_no,

        -- Tax
        is_txbl                                 as is_taxable,
        tax_categ_cod                           as tax_category_code,

        -- Grid / dimensions
        grid_dim_1_tag                          as grid_dim_1_tag,
        grid_dim_2_tag                          as grid_dim_2_tag,
        grid_dim_3_tag                          as grid_dim_3_tag,
        grid_ent_1                              as grid_entry_1,
        grid_ent_2                              as grid_entry_2,
        grid_ent_3                              as grid_entry_3,

        -- Alt units 1-5
        alt_1_unit                              as alt_1_unit,
        alt_1_numer                             as alt_1_numerator,
        alt_1_denom                             as alt_1_denominator,
        alt_1_prc_1                             as alt_1_price_1,
        alt_2_unit                              as alt_2_unit,
        alt_2_numer                             as alt_2_numerator,
        alt_2_denom                             as alt_2_denominator,
        alt_2_prc_1                             as alt_2_price_1,
        alt_3_unit                              as alt_3_unit,
        alt_3_numer                             as alt_3_numerator,
        alt_3_denom                             as alt_3_denominator,
        alt_3_prc_1                             as alt_3_price_1,
        alt_4_unit                              as alt_4_unit,
        alt_4_numer                             as alt_4_numerator,
        alt_4_denom                             as alt_4_denominator,
        alt_4_prc_1                             as alt_4_price_1,
        alt_5_unit                              as alt_5_unit,
        alt_5_numer                             as alt_5_numerator,
        alt_5_denom                             as alt_5_denominator,
        alt_5_prc_1                             as alt_5_price_1,

        -- Flags
        is_weighed                              as is_weighed,
        prompt_for_prc                          as prompt_for_price,
        prompt_for_cost                         as prompt_for_cost,
        prompt_for_descr                        as prompt_for_description,
        prompt_for_unit                         as prompt_for_unit,
        prompt_for_custom_flds                  as prompt_for_custom_fields,
        is_food_stmp_item                       as is_food_stamp_item,
        is_adm_tkt                              as is_admission_ticket,
        is_bom_par                              as is_bom_parent,
        is_kit_par                              as is_kit_parent,
        is_discntbl                             as is_discountable,
        item_is_misc                            as is_misc_item,
        is_ecomm_item                           as is_ecommerce_item,
        mix_match_cod                           as mix_match_code,

        -- Ecommerce
        ecomm_lst_pub_stat                      as ecomm_last_pub_status,
        ecomm_pub_stat                          as ecomm_pub_status,
        ecomm_img_file                          as ecomm_image_file,
        ecomm_new                               as ecomm_is_new,
        ecomm_on_specl                          as ecomm_on_special,
        ecomm_chrg_frt                          as ecomm_charge_freight,
        ecomm_frt_amt                           as ecomm_freight_amt,
        ecomm_disc_on_sal                       as ecomm_discount_on_sale,
        ecomm_item_is_discntbl                  as ecomm_item_is_discountable,
        ecomm_nxt_pub_typ                       as ecomm_next_pub_type,
        url                                     as ecomm_url,

        -- Serial number
        ser_no_req_for_sal                      as serial_no_required_for_sale,
        ser_prompt_cod_1                        as serial_prompt_code_1,
        ser_prompt_cod_2                        as serial_prompt_code_2,
        ser_prompt_cod_3                        as serial_prompt_code_3,

        -- Warranty
        warr_prd_1                              as warranty_period_1,
        warr_unit_1                             as warranty_unit_1,
        warr_prd_2                              as warranty_period_2,
        warr_unit_2                             as warranty_unit_2,

        -- Profile fields
        prof_alpha_1                            as profile_alpha_1,
        prof_alpha_2                            as profile_alpha_2,
        prof_alpha_3                            as profile_alpha_3,
        prof_alpha_4                            as profile_alpha_4,
        prof_alpha_5                            as profile_alpha_5,
        prof_cod_1                              as profile_code_1,
        prof_cod_2                              as profile_code_2,
        prof_cod_3                              as profile_code_3,
        prof_cod_4                              as profile_code_4,
        prof_cod_5                              as profile_code_5,
        prof_dat_1                              as profile_date_1,
        prof_dat_2                              as profile_date_2,
        prof_dat_3                              as profile_date_3,
        prof_dat_4                              as profile_date_4,
        prof_dat_5                              as profile_date_5,
        prof_no_1                               as profile_no_1,
        prof_no_2                               as profile_no_2,
        prof_no_3                               as profile_no_3,
        prof_no_4                               as profile_no_4,
        prof_no_5                               as profile_no_5,

        -- POS prompts
        ps_prompt_cod_1                         as ps_prompt_code_1,
        ps_prompt_cod_2                         as ps_prompt_code_2,
        ps_prompt_cod_3                         as ps_prompt_code_3,
        ps_lin_cust_fld_frm_id                  as ps_line_custom_field_form_id,

        -- Sync / audit
        copy_from_item_no                       as copy_from_item_no,
        rs_stat                                 as rs_status,
        row_ts                                  as row_timestamp,

        -- Dates
        try_to_timestamp(stat_dat)              as status_date,
        try_to_timestamp(lst_maint_dt)          as last_maintained_at,
        try_to_timestamp(lst_recv_dat)          as last_received_at,
        try_to_timestamp(lst_lck_dt)            as last_locked_at,
        try_to_timestamp(ecomm_lst_pub_dt)      as ecomm_last_published_at,
        try_to_timestamp(ecomm_on_specl_until)  as ecomm_on_special_until,
        try_to_timestamp(ecomm_new_until)       as ecomm_new_until,
        try_to_timestamp(rs_utc_dt)             as rs_utc_date,
        try_to_timestamp(ecomm_lst_chng_utc_dt) as ecomm_last_changed_utc,

        -- Maintenance user
        lst_maint_usr_id                        as last_maintained_by

    from source
)

select * from staged
