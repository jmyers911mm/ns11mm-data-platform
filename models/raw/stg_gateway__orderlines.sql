-- Staging model for Gateway Galaxy order lines (SEED_GATE_ORDERLINES)
-- Co-authored with CoCo

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_orderlines') }}
),

staged as (
    select
        -- Primary key
        orderlineid                             as order_line_id,
        orderlineguid                           as order_line_guid,

        -- Parent references
        orderid                                 as order_id,
        invoiceid                               as invoice_id,
        invoicelineid                           as invoice_line_id,

        -- Line details
        linenbr                                 as line_no,
        description                             as description,
        quantity                                as quantity,
        issuedquantity                          as issued_quantity,
        plu                                     as plu,

        -- Product / event
        detailtableid                           as detail_table_id,
        detailtype                              as detail_type,
        wsdetailtype                            as ws_detail_type,
        eventid                                 as event_id,
        eventname                               as event_name,
        reservationid                           as reservation_id,

        -- Pricing
        amount                                  as amount,
        total                                   as total,
        taxamount                               as tax_amount,
        pricebasis                              as price_basis,

        -- Discounts
        discountamount                          as discount_amount,
        discountbarcode                         as discount_barcode,
        hasdiscount                             as has_discount,
        externaldiscountid                      as external_discount_id,
        externaldiscountname                    as external_discount_name,

        -- Ticket / pass details
        visualid                                as visual_id,
        packagevisualid                         as package_visual_id,
        ticketdate                              as ticket_date_raw,
        nameonpass                              as name_on_pass,
        passid                                  as pass_id,
        ispassrequired                          as is_pass_required,
        entitlementaddonvisualid                as entitlement_addon_visual_id,
        entitlementgroupid                      as entitlement_group_id,

        -- Upgrade
        upgradevalue                            as upgrade_value,
        hasmodifiedupgradevalue                 as has_modified_upgrade_value,
        modifiedupgradevalue                    as modified_upgrade_value,
        upgradevaluemodificationtype            as upgrade_value_modification_type,
        ismandatoryupgrade                      as is_mandatory_upgrade,

        -- Package
        packagedetailid                         as package_detail_id,
        pkginstancedetailid                     as pkg_instance_detail_id,
        ispackageonthefly                       as is_package_on_the_fly,
        packageprintsequence                    as package_print_sequence,
        externaldynamicpackageheaderid          as external_dynamic_package_header_id,
        externaldynamicpackagedetailid          as external_dynamic_package_detail_id,

        -- Status flags
        batchdetailsid                          as batch_details_id,
        qtyinbatch                              as qty_in_batch,
        systemsplitline                         as system_split_line,
        isnotprinted                            as is_not_printed,
        hasguests                               as has_guests,
        isassociatedticket                      as is_associated_ticket,
        isonlineexchange                        as is_online_exchange,
        deferredentitlement                     as is_deferred_entitlement,
        preventrecalculation                    as prevent_recalculation,

        -- Capacity / seating
        capacityid                              as capacity_id,
        rseventseatmapid                        as rs_event_seat_map_id,

        -- Shipping
        shippingplu                             as shipping_plu,
        deliverymethodgroupid                   as delivery_method_group_id,

        -- Rental
        rentalserialid                          as rental_serial_id,
        hasrentalinventory                      as has_rental_inventory,
        resourceid                              as resource_id,

        -- Guest / contact
        leadguestid                             as lead_guest_id,
        guestid                                 as guest_id,
        contactid                               as contact_id,
        roomid                                  as room_id,

        -- Loyalty
        pendingloyaltypoints                    as pending_loyalty_points,
        issuedloyaltypoints                     as issued_loyalty_points,
        loyaltyaccountno                        as loyalty_account_no,
        loyaltyprogramid                        as loyalty_program_id,
        points                                  as points,
        redeemedvalue                           as redeemed_value,

        -- Gift aid
        giftaidamount                           as gift_aid_amount,
        giftaidtype                             as gift_aid_type,
        orderlinegiftdetailid                   as order_line_gift_detail_id,

        -- Sales channel / program
        saleschannelid                          as sales_channel_id,
        saleschanneldetailid                    as sales_channel_detail_id,
        salesupervisorid                        as sale_supervisor_id,
        salesprogramid                          as sales_program_id,
        salessubcategoryid                      as sales_subcategory_id,
        priceprogramid                          as price_program_id,
        pricetoken                              as price_token,
        issuancetype                            as issuance_type,

        -- Disbursement / payment
        disbursementid                          as disbursement_id,
        paymentcontractid                       as payment_contract_id,
        paymentplanid                           as payment_plan_id,
        creditmemoid                            as credit_memo_id,

        -- Notes / reference
        noteid                                  as note_id,
        groupid                                 as group_id,
        baseid                                  as base_id,
        busid                                   as bus_id,
        transid2                                as trans_id_2,
        externalreferenceid                     as external_reference_id,

        -- Node
        nodeno                                  as node_no,

        -- Misc
        attributevaluegroupid                   as attribute_value_group_id,
        recordversion                           as record_version,
        lastupdatedby                           as last_updated_by,

        -- Dates
        try_to_timestamp(ticketdate)            as ticket_date,
        try_to_timestamp(eventticketdate)       as event_ticket_date,
        try_to_timestamp(eventticketenddate)    as event_ticket_end_date,
        try_to_timestamp(newexppass)            as new_exp_pass_date,
        try_to_timestamp(expirationdate)        as expiration_date,
        try_to_timestamp(expirationoverridedate) as expiration_override_date,
        try_to_timestamp(createdate)            as created_at,
        try_to_timestamp(lastupdate)            as last_updated_at,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
where order_line_id is not null
qualify row_number() over (partition by order_line_id order by _loaded_at desc) = 1
