-- Bronze staging: CounterPoint POS ticket-history headers
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per doc_id (dedup: latest _loaded_at wins)
--
-- Conforms seed_cp_pstkthist (posted POS ticket headers: store, station,
-- business date, totals) into snake_case. The header partner to
-- stg_counterpoint__pstkthistlin.
--
-- ADR-001: rename/recast only, no business logic (that lands in the int_ layer).

{{ config(materialized='view') }}

with source as (
    select * from {{ source('counterpoint_seed', 'seed_cp_pstkthist') }}
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
        data_upgrade_stat                       as data_upgrade_status,
        agg_stat                                as aggregate_status,
        is_offline                              as is_offline,

        -- Loyalty
        loy_pgm_cod                             as loyalty_program_code,

        -- Shipping
        terms_cod                               as terms_code,
        ship_via_cod                            as ship_via_code,
        ship_zone_cod                           as ship_zone_code,

        -- Tax
        norm_tax_cod                            as normal_tax_code,
        tax_cod                                 as tax_code,
        tax_exempt_no                           as tax_exempt_no,
        has_tax_ovrd                            as has_tax_override,
        tax_ovrd_reas                           as tax_override_reason,
        tax_ovrd_lins                           as tax_override_lines,

        -- Customer PO
        cust_po_no                              as customer_po_no,
        ref                                     as reference,

        -- Printing
        lst_frm_grp_prtd                        as last_form_group_printed,
        lst_frm_prtd                            as last_form_printed,
        times_prtd                              as times_printed,

        -- Line counts
        lins                                    as total_lines,
        sal_lins                                as sale_lines,
        ret_lins                                as return_lines,
        gfc_lins                                as gift_card_lines,
        svc_lins                                as service_lines,

        -- Totals
        sub_tot                                 as subtotal,
        tot                                     as total,
        sal_lin_tot                             as sale_line_total,
        ret_lin_tot                             as return_line_total,
        tot_ext_cost                            as total_ext_cost,
        tot_weight                              as total_weight,
        tot_cube                                as total_cube,
        tot_gfc_amt                             as total_gift_card_amt,
        tot_svc_amt                             as total_service_amt,
        tot_misc                                as total_misc,
        norm_tax_amt                            as normal_tax_amt,
        tax_amt                                 as tax_amt,
        tot_tnd                                 as total_tendered,
        tot_chng                                as total_change,
        tot_hdr_disc                            as total_header_discount,
        tot_lin_disc                            as total_line_discount,
        tot_tip_amt                             as total_tip_amt,

        -- Food stamps
        food_stmp_amt                           as food_stamp_amt,
        food_stmp_lins                          as food_stamp_lines,
        food_stmp_tax_amt                       as food_stamp_tax_amt,
        food_stmp_norm_tax_amt                  as food_stamp_normal_tax_amt,

        -- Dates
        try_to_timestamp(tkt_dt)                as ticket_date,
        try_to_timestamp(ship_dat)              as ship_date,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
qualify row_number() over (partition by doc_id order by _loaded_at desc) = 1
