-- Staging model for Gateway Galaxy orders (SEED_GATE_ORDERS)
-- Co-authored with CoCo

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_orders') }}
),

staged as (
    select
        -- Primary key
        orderid                                 as order_id,

        -- Order identifiers
        orderguid                               as order_guid,
        orderhash                               as order_hash,
        externalid                              as external_id,
        unformattedexternalid                   as unformatted_external_id,

        -- Transaction context
        nodeno                                  as node_no,
        sessionid                               as session_id,
        aspnetsessionid                         as aspnet_session_id,
        spconnectionid                          as sp_connection_id,

        -- Customer
        customerid                              as customer_id,
        accountid                               as account_id,
        contactid                               as contact_id,
        billtocontactid                         as bill_to_contact_id,
        shiptocontactid                         as ship_to_contact_id,
        custcategoryid                          as customer_category_id,

        -- Group
        groupvisitid                            as group_visit_id,
        groupsalescode                          as group_sales_code,

        -- Status
        orderstatus                             as order_status,
        orderresolution                         as order_resolution,
        externalorderstatus                     as external_order_status,
        locked                                  as is_locked,
        lockedpaymentstate                      as locked_payment_state,
        secure                                  as is_secure,
        permitreturnsonly                        as permit_returns_only,

        -- Financials
        orderamt                                as order_amount,
        totaltax                                as total_tax,
        totalshipping                           as total_shipping,
        totaldiscount                           as total_discount,
        totalpayment                            as total_payment,
        totalpromotionaldiscount                as total_promotional_discount,
        totalredeemedvalue                      as total_redeemed_value,
        balance                                 as balance,
        minimumpaymentdue                       as minimum_payment_due,
        unissuedqty                             as unissued_qty,
        unissuedamt                             as unissued_amt,
        taxstatus                               as tax_status,
        payonissuance                           as pay_on_issuance,

        -- Loyalty
        pendingloyaltybonuspoints               as pending_loyalty_bonus_points,
        issuedloyaltybonuspoints                as issued_loyalty_bonus_points,
        loyaltyaccountno                        as loyalty_account_no,
        loyaltyprogramid                        as loyalty_program_id,

        -- Gift aid
        giftaidstatus                           as gift_aid_status,

        -- Delivery
        deliverymethod                          as delivery_method,
        deliverymethodid                        as delivery_method_id,
        deliverydetails                         as delivery_details,
        trackingnbr                             as tracking_number,
        pickupnode                              as pickup_node,
        pickupuserid                            as pickup_user_id,

        -- Sales / promotion
        salesperson                             as salesperson,
        salesprogramid                          as sales_program_id,
        salescategorygroupid                    as sales_category_group_id,
        promotionid                             as promotion_id,
        promotioncode                           as promotion_code,
        promotionofferid                        as promotion_offer_id,
        merchantid                              as merchant_id,
        egalaxysource                           as egalaxysource,
        giftedpurchase                          as is_gifted_purchase,
        lastmenuid                              as last_menu_id,

        -- Network
        remoteaddress                           as remote_address,
        serveraddress                           as server_address,

        -- Notes / reference
        noteid                                  as note_id,
        reference                               as reference,
        po                                      as po_number,
        vieworderweburl                         as view_order_web_url,

        -- Misc
        attributevaluegroupid                   as attribute_value_group_id,
        translationlanguageid                   as translation_language_id,
        personalmessageid                       as personal_message_id,
        securetoken                             as secure_token,
        recordversion                           as record_version,
        lastupdatedby                           as last_updated_by,

        -- Dates
        try_to_timestamp(opendate)              as open_date,
        try_to_timestamp(batchprintdate)        as batch_print_date,
        try_to_timestamp(pickupdate)            as pickup_date,
        try_to_timestamp(lastupdate)            as last_updated_at,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
where order_id is not null
qualify row_number() over (partition by order_id order by _loaded_at desc) = 1
