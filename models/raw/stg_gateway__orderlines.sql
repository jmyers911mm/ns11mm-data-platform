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
        orderno                                 as order_no,
        nodeno                                  as node_no,

        -- Line details
        lineno                                  as line_no,
        qty                                     as quantity,
        plu                                     as plu,
        descr                                   as description,

        -- Product classification
        productno                               as product_no,
        company                                 as company_id,
        category                                as category,
        subcat                                  as subcategory,
        eventno                                 as event_no,
        eventname                               as event_name,

        -- Pricing
        price                                   as price,
        unitprice                               as unit_price,
        tax                                     as tax,
        taxmethods                              as tax_methods,
        commission                              as commission,
        discid                                  as discount_id,
        discamt                                 as discount_amt,
        externaldiscountid                      as external_discount_id,
        externaldiscountname                    as external_discount_name,

        -- Ticket / pass details
        accesscode                              as access_code,
        tktcode                                 as ticket_code,
        visualid                                as visual_id,
        packagevisualid                         as package_visual_id,
        nameonpass                              as name_on_pass,
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
        pkginstancedetailid                     as pkg_instance_detail_id,
        ispackageonthefly                       as is_package_on_the_fly,
        packageprintsequence                    as package_print_sequence,
        externaldynamicpackageheaderid          as external_dynamic_package_header_id,
        externaldynamicpackagedetailid          as external_dynamic_package_detail_id,

        -- Status flags
        status                                  as status_code,
        printed                                 as is_printed,
        isnotprinted                            as is_not_printed,
        void                                    as is_void,
        hasguests                               as has_guests,
        isassociatedticket                      as is_associated_ticket,
        isonlineexchange                        as is_online_exchange,
        deferredentitlement                     as is_deferred_entitlement,
        preventrecalculation                    as prevent_recalculation,

        -- Shipping
        shippingplu                             as shipping_plu,

        -- Loyalty
        pendingloyaltypoints                    as pending_loyalty_points,
        issuedloyaltypoints                     as issued_loyalty_points,
        loyaltyaccountno                        as loyalty_account_no,
        loyaltyprogramid                        as loyalty_program_id,

        -- Gift aid
        giftaidamount                           as gift_aid_amount,
        giftaidtype                             as gift_aid_type,

        -- Channel
        saleschannelid                          as sales_channel_id,
        salesupervisorid                        as sale_supervisor_id,
        priceprogramid                          as price_program_id,
        pricetoken                              as price_token,
        issuancetype                            as issuance_type,

        -- Dates
        try_to_timestamp(eventticketdate)       as event_ticket_date,
        try_to_timestamp(eventticketenddate)    as event_ticket_end_date,
        try_to_timestamp(newexppass)            as new_exp_pass_date,
        try_to_timestamp(expirationoverridedate) as expiration_override_date,
        try_to_timestamp(lastupdate)            as last_updated_at,

        -- References
        baseid                                  as base_id,
        busid                                   as bus_id,
        transid2                                as trans_id_2,
        rseventseatmapid                        as rs_event_seat_map_id,
        externalreferenceid                     as external_reference_id,
        redeemedvalue                           as redeemed_value,
        attributevaluegroupid                   as attribute_value_group_id,
        recordversion                           as record_version,
        lastupdatedby                           as last_updated_by,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
