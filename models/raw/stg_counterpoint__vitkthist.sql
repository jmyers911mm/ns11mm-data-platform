-- Staging model for CounterPoint ticket history view - headers (SEED_CP_VITKTHIST)
-- Co-authored with CoCo

{{ config(materialized='view') }}

with source as (
    select * from {{ source('counterpoint_seed', 'seed_cp_vitkthist') }}
),

staged as (
    select
        -- Primary key
        doc_id                                  as doc_id,
        doc_guid                                as doc_guid,

        -- Transaction identifiers
        tkt_no                                  as ticket_no,
        bus_dat                                 as business_date,
        event_no                                as event_no,
        doc_typ                                 as doc_type,
        doc_descr                               as doc_description,

        -- Location
        str_id                                  as store_id,
        sta_id                                  as station_id,
        stk_loc_id                              as stock_location_id,
        prc_loc_id                              as price_location_id,
        pft_ctr                                 as profit_center,

        -- Customer
        cust_no                                 as customer_no,
        bill_to_contact_id                      as bill_to_contact_id,
        ship_to_contact_id                      as ship_to_contact_id,

        -- Personnel
        usr_id                                  as user_id,
        sls_rep                                 as sales_rep,
        drw_id                                  as drawer_id,
        drw_session_id                          as drawer_session_id,

        -- Ticket type / status
        tkt_typ                                 as is_return,
        ref                                     as reference,

        -- Tax
        norm_tax_cod                            as normal_tax_code,
        tax_cod                                 as tax_code,
        tax_cod_chngd                           as tax_code_changed,
        tax_exempt_no                           as tax_exempt_no,
        tax_ovrd_reas                           as tax_override_reason,
        tax_ovrd_lins                           as tax_override_lines,

        -- Shipping / terms
        terms_cod                               as terms_code,
        ship_via_cod                            as ship_via_code,
        ship_zone_cod                           as ship_zone_code,
        loy_pgm_cod                             as loyalty_program_code,
        cust_po_no                              as customer_po_no,

        -- Line counts
        lins                                    as total_lines,
        sal_lins                                as sale_lines,
        ret_lins                                as return_lines,
        gfc_lins                                as gift_card_lines,
        svc_lins                                as service_lines,

        -- Combined totals
        gross_sub_tot                           as gross_subtotal,
        sub_tot                                 as subtotal,
        tot                                     as total,
        tot_hdr_disc                            as total_header_discount,
        tot_lin_disc                            as total_line_discount,
        tot_disc                                as total_discount,
        tot_cost                                as total_cost,
        tot_weight                              as total_weight,
        tot_cube                                as total_cube,
        tot_misc                                as total_misc,
        norm_tax_amt                            as normal_tax_amt,
        tax_amt                                 as tax_amt,
        tot_tnd                                 as total_tendered,
        tot_chng                                as total_change,
        net_tnd                                 as net_tendered,
        amt_due                                 as amount_due,
        tot_tip_amt                             as total_tip_amt,
        tot_tnd_amt                             as total_tender_amt,

        -- Sale-specific totals
        sal_gross_sub_tot                       as sale_gross_subtotal,
        sal_sub_tot                             as sale_subtotal,
        sal_tot                                 as sale_total,
        sal_tot_hdr_disc                        as sale_total_header_discount,
        sal_tot_lin_disc                        as sale_total_line_discount,
        sal_tot_disc                            as sale_total_discount,
        sal_tot_cost                            as sale_total_cost,
        sal_tot_est_cost                        as sale_total_est_cost,
        sal_tot_weight                          as sale_total_weight,
        sal_tot_cube                            as sale_total_cube,
        sal_tot_gfc_amt                         as sale_total_gift_card_amt,
        sal_tot_svc_amt                         as sale_total_service_amt,
        sal_tot_misc                            as sale_total_misc,
        sal_norm_tax_amt                        as sale_normal_tax_amt,
        sal_tax_amt                             as sale_tax_amt,
        sal_tot_tnd                             as sale_total_tendered,
        sal_tot_chng                            as sale_total_change,
        sal_net_tnd                             as sale_net_tendered,
        sal_amt_due                             as sale_amount_due,
        sal_only_net_tnd                        as sale_only_net_tendered,
        sal_amt_received                        as sale_amount_received,
        sal_tot_tnd_amt                         as sale_total_tender_amt,
        sal_lin_tot                             as sale_line_total,
        ret_lin_tot                             as return_line_total,
        sal_has_tax_ovrd                        as sale_has_tax_override,
        sal_tax_ovrd_lins                       as sale_tax_override_lines,

        -- Misc amounts (1-5)
        misc_amt_1                              as misc_amt_1,
        misc_amt_2                              as misc_amt_2,
        misc_amt_3                              as misc_amt_3,
        misc_amt_4                              as misc_amt_4,
        misc_amt_5                              as misc_amt_5,
        misc_pct_1                              as misc_pct_1,
        misc_pct_2                              as misc_pct_2,
        misc_pct_3                              as misc_pct_3,
        misc_pct_4                              as misc_pct_4,
        misc_pct_5                              as misc_pct_5,

        -- Sale misc types/amounts
        sal_misc_typ_1                          as sale_misc_type_1,
        sal_misc_amt_1                          as sale_misc_amt_1,
        sal_misc_pct_1                          as sale_misc_pct_1,
        sal_misc_typ_2                          as sale_misc_type_2,
        sal_misc_amt_2                          as sale_misc_amt_2,
        sal_misc_pct_2                          as sale_misc_pct_2,
        sal_misc_typ_3                          as sale_misc_type_3,
        sal_misc_amt_3                          as sale_misc_amt_3,
        sal_misc_pct_3                          as sale_misc_pct_3,
        sal_misc_typ_4                          as sale_misc_type_4,
        sal_misc_amt_4                          as sale_misc_amt_4,
        sal_misc_pct_4                          as sale_misc_pct_4,
        sal_misc_typ_5                          as sale_misc_type_5,
        sal_misc_amt_5                          as sale_misc_amt_5,
        sal_misc_pct_5                          as sale_misc_pct_5,

        -- Misc tax allocations
        misc_tax_amt_alloc_1                    as misc_tax_alloc_1,
        misc_norm_tax_amt_alloc_1               as misc_norm_tax_alloc_1,
        misc_tax_amt_alloc_2                    as misc_tax_alloc_2,
        misc_norm_tax_amt_alloc_2               as misc_norm_tax_alloc_2,
        misc_tax_amt_alloc_3                    as misc_tax_alloc_3,
        misc_norm_tax_amt_alloc_3               as misc_norm_tax_alloc_3,
        misc_tax_amt_alloc_4                    as misc_tax_alloc_4,
        misc_norm_tax_amt_alloc_4               as misc_norm_tax_alloc_4,
        misc_tax_amt_alloc_5                    as misc_tax_alloc_5,
        misc_norm_tax_amt_alloc_5               as misc_norm_tax_alloc_5,
        sal_misc_tax_amt_alloc_1                as sale_misc_tax_alloc_1,
        sal_misc_norm_tax_amt_alloc_1           as sale_misc_norm_tax_alloc_1,
        sal_misc_tax_amt_alloc_2                as sale_misc_tax_alloc_2,
        sal_misc_norm_tax_amt_alloc_2           as sale_misc_norm_tax_alloc_2,
        sal_misc_tax_amt_alloc_3                as sale_misc_tax_alloc_3,
        sal_misc_norm_tax_amt_alloc_3           as sale_misc_norm_tax_alloc_3,
        sal_misc_tax_amt_alloc_4                as sale_misc_tax_alloc_4,
        sal_misc_norm_tax_amt_alloc_4           as sale_misc_norm_tax_alloc_4,
        sal_misc_tax_amt_alloc_5                as sale_misc_tax_alloc_5,
        sal_misc_norm_tax_amt_alloc_5           as sale_misc_norm_tax_alloc_5,

        -- Header discounts
        hdr_discs                               as header_discounts,
        hdr_disc_cod                            as header_discount_code,

        -- Payment
        pay_acct_no                             as payment_account_no,
        pay_apply_meth                          as payment_apply_method,
        pay_amt                                 as payment_amount,
        abs_pay_amt                             as abs_payment_amount,
        dep_only_tkt                            as is_deposit_only_ticket,

        -- Food stamps
        food_stmp_amt                           as food_stamp_amt,
        food_stmp_lins                          as food_stamp_lines,
        food_stmp_tax_amt                       as food_stamp_tax_amt,

        -- Printing
        lst_frm_grp_prtd                        as last_form_group_printed,
        lst_frm_prtd                            as last_form_printed,
        times_prtd                              as times_printed,

        -- Loyalty
        lin_loy_pts_earnd                       as line_loyalty_pts_earned,
        loy_pts_earnd_gross                     as loyalty_pts_earned_gross,
        loy_pts_adj_for_rdm                     as loyalty_pts_adj_for_redeem,
        loy_pts_adj_for_inc_rnd                 as loyalty_pts_adj_for_inc_round,
        loy_pts_adj_for_over_max                as loyalty_pts_adj_for_over_max,
        loy_pts_earnd_net                       as loyalty_pts_earned_net,
        loy_pts_rdm                             as loyalty_pts_redeemed,
        loy_pts_bal                             as loyalty_pts_balance,

        -- Ecommerce
        ec_str_id                               as ecomm_store_id,
        ec_imp_event_no                         as ecomm_import_event_no,
        ec_ord_no                               as ecomm_order_no,
        ec_bat_id                               as ecomm_batch_id,
        ec_cust_no                              as ecomm_customer_no,
        ec_affil_cod                            as ecomm_affiliate_code,
        ec_ord_tot                              as ecomm_order_total,

        -- Billing address
        bill_nam                                as bill_name,
        bill_fst_nam                            as bill_first_name,
        bill_lst_nam                            as bill_last_name,
        bill_salutation                         as bill_salutation,
        bill_adrs_1                             as bill_address_1,
        bill_adrs_2                             as bill_address_2,
        bill_adrs_3                             as bill_address_3,
        bill_city                               as bill_city,
        bill_state                              as bill_state,
        bill_zip_cod                            as bill_zip_code,
        bill_cntry                              as bill_country,
        bill_phone_1                            as bill_phone_1,
        bill_phone_2                            as bill_phone_2,
        bill_email_adrs_1                       as bill_email_1,
        bill_email_adrs_2                       as bill_email_2,
        bill_contct_1                           as bill_contact_1,
        bill_contct_2                           as bill_contact_2,
        bill_fax_1                              as bill_fax_1,
        bill_fax_2                              as bill_fax_2,
        bill_nam_typ                            as bill_name_type,
        bill_fst_lst_nam                        as bill_first_last_name,

        -- Shipping address
        ship_nam                                as ship_name,
        ship_fst_nam                            as ship_first_name,
        ship_lst_nam                            as ship_last_name,
        ship_salutation                         as ship_salutation,
        ship_adrs_1                             as ship_address_1,
        ship_adrs_2                             as ship_address_2,
        ship_adrs_3                             as ship_address_3,
        ship_city                               as ship_city,
        ship_state                              as ship_state,
        ship_zip_cod                            as ship_zip_code,
        ship_cntry                              as ship_country,
        ship_phone_1                            as ship_phone_1,
        ship_phone_2                            as ship_phone_2,
        ship_adrs_id                            as ship_address_id,
        ship_email_adrs_1                       as ship_email_1,
        ship_email_adrs_2                       as ship_email_2,
        ship_contct_1                           as ship_contact_1,
        ship_contct_2                           as ship_contact_2,
        ship_fax_1                              as ship_fax_1,
        ship_fax_2                              as ship_fax_2,
        ship_nam_typ                            as ship_name_type,
        ship_fst_lst_nam                        as ship_first_last_name,

        -- Profile fields
        prof_cod_1                              as profile_code_1,
        prof_cod_2                              as profile_code_2,
        prof_cod_3                              as profile_code_3,
        prof_cod_4                              as profile_code_4,
        prof_cod_5                              as profile_code_5,
        prof_no_1                               as profile_no_1,
        prof_no_2                               as profile_no_2,
        prof_no_3                               as profile_no_3,
        prof_no_4                               as profile_no_4,
        prof_no_5                               as profile_no_5,
        prof_alpha_1                            as profile_alpha_1,
        prof_alpha_2                            as profile_alpha_2,
        prof_alpha_3                            as profile_alpha_3,
        prof_alpha_4                            as profile_alpha_4,
        prof_alpha_5                            as profile_alpha_5,
        prof_dat_1                              as profile_date_1,
        prof_dat_2                              as profile_date_2,
        prof_dat_3                              as profile_date_3,
        prof_dat_4                              as profile_date_4,
        prof_dat_5                              as profile_date_5,

        -- Original order
        orig_ord_str_id                         as orig_order_store_id,
        orig_ord_sta_id                         as orig_order_station_id,
        orig_ord_no                             as orig_order_no,
        orig_ord_tot                            as orig_order_total,
        orig_ord_amt_due                        as orig_order_amount_due,
        orig_ord_doc_id                         as orig_order_doc_id,
        orig_ord_cancelled                      as orig_order_cancelled,
        orig_ord_is_active                      as orig_order_is_active,

        -- Order deposits
        ord_dep_amt_received                    as order_deposit_received,
        ord_dep_amt_applied                     as order_deposit_applied,
        ord_dep_amt_forfeit                     as order_deposit_forfeit,
        ord_dep_amt_refunded                    as order_deposit_refunded,
        ord_dep_net_change                      as order_deposit_net_change,
        ord_dep_bal_before                      as order_deposit_bal_before,
        ord_dep_bal_after                       as order_deposit_bal_after,

        -- Original quote
        orig_quot_str_id                        as orig_quote_store_id,
        orig_quot_sta_id                        as orig_quote_station_id,
        orig_quot_no                            as orig_quote_no,

        -- Original hold
        orig_hold_str_id                        as orig_hold_store_id,
        orig_hold_sta_id                        as orig_hold_station_id,
        orig_hold_no                            as orig_hold_no,

        -- Layaway
        orig_lwy_str_id                         as orig_layaway_store_id,
        orig_lwy_sta_id                         as orig_layaway_station_id,
        orig_lwy_no                             as orig_layaway_no,
        orig_lwy_tot                            as orig_layaway_total,
        orig_lwy_amt_due                        as orig_layaway_amount_due,
        orig_lwy_doc_id                         as orig_layaway_doc_id,
        orig_lwy_cancelled                      as orig_layaway_cancelled,
        orig_lwy_is_active                      as orig_layaway_is_active,
        lwy_dep_amt_received                    as layaway_deposit_received,
        lwy_dep_amt_applied                     as layaway_deposit_applied,
        lwy_dep_amt_forfeit                     as layaway_deposit_forfeit,
        lwy_dep_amt_refunded                    as layaway_deposit_refunded,
        lwy_dep_net_change                      as layaway_deposit_net_change,
        lwy_dep_bal_before                      as layaway_deposit_bal_before,
        lwy_dep_bal_after                       as layaway_deposit_bal_after,

        -- Doc status
        orig_doc_stat                           as orig_doc_status,
        dep_amt_received                        as deposit_amt_received,
        dep_amt_applied                         as deposit_amt_applied,
        dep_amt_forfeit                         as deposit_amt_forfeit,
        dep_amt_refunded                        as deposit_amt_refunded,
        dep_net_change                          as deposit_net_change,
        dep_bal_before                          as deposit_bal_before,
        dep_bal_after                           as deposit_bal_after,

        -- Date parts
        tkt_dat_mon                             as ticket_date_month,
        tkt_dat_week                            as ticket_date_week,
        tkt_dat_qtr                             as ticket_date_quarter,
        tkt_dat_dow                             as ticket_date_dow,
        tkt_tim_hr                              as ticket_time_hour,
        tkt_dat_md                              as ticket_date_md,

        -- BLoyal loyalty
        user_bloyal_loy_pts_used                as bloyal_pts_used,
        user_bloyal_loy_pts_accrued             as bloyal_pts_accrued,
        user_bloyal_loy_pts_total               as bloyal_pts_total,
        user_bloyal_loy_pts_starting            as bloyal_pts_starting,
        user_bloyal_cartuid                     as bloyal_cart_uid,
        user_bloyal_loy_cur_used                as bloyal_currency_used,
        user_bloyal_loy_cur_accrued             as bloyal_currency_accrued,
        user_bloyal_loy_cur_total               as bloyal_currency_total,
        user_bloyal_loy_cur_starting            as bloyal_currency_starting,

        -- Extended keys
        bus_dat_ext                             as business_date_ext,
        doc_id_ext                              as doc_id_ext,

        -- Dates
        tkt_tim                                 as ticket_time,
        post_dat                                as post_date,
        try_to_timestamp(tkt_dt)                as ticket_date,
        try_to_timestamp(ship_dat)              as ship_date,
        try_to_timestamp(ec_lst_pub_dt)         as ecomm_last_published_at,
        try_to_timestamp(orig_ord_dat)          as orig_order_date,
        try_to_timestamp(orig_ord_tim)          as orig_order_time,
        try_to_timestamp(orig_lwy_dat)          as orig_layaway_date,
        try_to_timestamp(orig_lwy_tim)          as orig_layaway_time

    from source
)

select * from staged
