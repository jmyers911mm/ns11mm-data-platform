-- Bronze staging: Gateway (Galaxy) journal tickets
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (DPR base)
-- Grain:  one row per jnl_detail_id (dedup: latest _loaded_at wins)
--
-- Conforms seed_gate_jnltickets, the ticket-specific detail (visual id, plu,
-- price, discounts, seating, membership, gift aid) that joins 1:1 to jnldetails
-- on jnl_detail_id. plu and custno are trimmed to stay aligned with the item
-- catalog. Core input to int_gateway__ticket_journal_lines.
--
-- ADR-001: rename/recast only, no business logic (that lands in the int_ layer).

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_jnltickets') }}
),

staged as (
    select
        -- Primary key
        jnldetailid                             as jnl_detail_id,
        jnlticketguid                           as jnl_ticket_guid,

        -- Ticket identifiers
        visualid                                as visual_id,
        accesscode                              as access_code,
        id                                      as barcode_id,
        externalid                              as external_id,

        -- Transaction context
        nodeno                                  as node_no,
        transno                                 as trans_no,
        linenum                                 as line_num,
        serial                                  as serial_no,
        orderno                                 as order_no,
        eventno                                 as event_no,

        -- Product / pricing
        company                                 as company_id,
        tktcode                                 as ticket_code,
        -- trim: keep aligned with stg_gateway__items.plu (CHAR(20) padded in source)
        trim(plu)                               as plu,
        productno                               as product_no,
        fkeyno                                  as function_key_no,
        qty                                     as quantity,
        tktindex                                as ticket_index,
        price                                   as price,
        unitprice                               as unit_price,
        tax                                     as tax,
        taxes                                   as tax_flags,
        taxmethods                              as tax_methods,
        taxtableid                              as tax_table_id,
        commission                              as commission,
        remainingvalue                          as remaining_value,
        upgradevalue                            as upgrade_value,
        redeemedvalue                           as redeemed_value,

        -- Discounts
        discno                                  as discount_no,
        discamt                                 as discount_amt,
        discindex                               as discount_index,
        coupons                                 as coupon_count,

        -- Status and usage
        status                                  as status_code,
        usecount                                as use_count,
        useqty                                  as use_qty,
        lastacp                                 as last_acp_id,
        updatecode                              as update_code,

        -- Customer
        customerid                              as customer_id,
        trim(custno)                            as customer_no,
        contactid                               as contact_id,
        firstname                               as first_name,
        lastname                                as last_name,

        -- Capacity / seating
        capacityid                              as capacity_id,
        rseventseatmapid                        as rs_event_seat_map_id,
        rseventseatid                           as rs_event_seat_id,
        sectionname                             as section_name,
        rowname                                 as row_name,
        seatname                                as seat_name,

        -- Sales context
        salesprogramid                          as sales_program_id,
        supervisorid                            as supervisor_id,
        disbursementid                          as disbursement_id,
        saleschannelid                          as sales_channel_id,
        deliverymethodid                        as delivery_method_id,
        pricescheduleid                         as price_schedule_id,
        pricetoken                              as price_token,

        -- Resource
        resourceid                              as resource_id,
        jnltripsummaryid                        as jnl_trip_summary_id,

        -- Loyalty / gift aid
        loyaltypoints                           as loyalty_points,
        points                                  as points,
        giftaidamount                           as gift_aid_amount,
        giftaidtype                             as gift_aid_type,

        -- Upsell
        upsellstatus                            as upsell_status,
        upsellplu                               as upsell_plu,
        upsellpricedifference                   as upsell_price_difference,
        upselltype                              as upsell_type,
        upselluserid                            as upsell_user_id,
        upsellsaleschanneltype                  as upsell_sales_channel_type,

        -- Membership
        memberaddonid                           as member_addon_id,
        entitlementaddonvisualid                as entitlement_addon_visual_id,
        entitlementgroupid                      as entitlement_group_id,

        -- Package
        pkginstancedetailid                     as pkg_instance_detail_id,
        packageprintsequence                    as package_print_sequence,

        -- RFID
        rfidserial                              as rfid_serial,
        rfidserialprefix                        as rfid_serial_prefix,
        rfidserialsuffix                        as rfid_serial_suffix,

        -- Flags
        preprinted                              as is_preprinted,
        duplicate                               as is_duplicate,
        reprinted                               as is_reprinted,
        acct                                    as account_code,
        requirespassownerscan                   as requires_pass_owner_scan,
        attributevaluegroupid                   as attribute_value_group_id,
        endoflifedatestatus                     as end_of_life_date_status,
        endoflifelockwindow                     as end_of_life_lock_window,
        recordversion                           as record_version,
        lastupdatedby                           as last_updated_by,

        -- Dates
        try_to_timestamp(datesold)              as sold_at,
        try_to_timestamp(ticketdate)            as ticket_date,
        try_to_timestamp(lastuse)               as last_use_at,
        try_to_timestamp(expiration)            as expires_at,
        try_to_timestamp(activatebydate)        as activate_by_date,
        try_to_timestamp(endoflifedate)         as end_of_life_date,
        try_to_timestamp(lastupdate)            as last_updated_at,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
qualify row_number() over (partition by jnl_detail_id order by _loaded_at desc) = 1