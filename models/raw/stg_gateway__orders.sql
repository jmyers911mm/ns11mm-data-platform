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
        orderno                                 as order_no,
        orderguid                               as order_guid,
        orderhash                               as order_hash,
        externalid                              as external_id,

        -- Transaction context
        nodeno                                  as node_no,
        transno                                 as trans_no,
        eventno                                 as event_no,
        sessionid                               as session_id,
        aspnetsessionid                         as aspnet_session_id,

        -- Customer
        customerid                              as customer_id,
        contactid                               as contact_id,

        -- Status
        status                                  as status_code,
        locked                                  as is_locked,
        lockedpaymentstate                      as locked_payment_state,

        -- Financials
        total                                   as total,
        tax                                     as tax,
        totalshipping                           as total_shipping,
        totaldiscount                           as total_discount,
        totalpaid                               as total_paid,
        totalrefund                             as total_refund,
        totaldue                                as total_due,
        depositamt                              as deposit_amt,

        -- Loyalty
        pendingloyaltypoints                    as pending_loyalty_points,
        issuedloyaltypoints                     as issued_loyalty_points,
        pendingloyaltybonuspoints               as pending_loyalty_bonus_points,
        issuedloyaltybonuspoints                as issued_loyalty_bonus_points,

        -- Gift aid
        giftaidstatus                           as gift_aid_status,

        -- Channel / sales
        salesperson                             as salesperson,
        merchantid                              as merchant_id,
        promotionofferid                        as promotion_offer_id,
        egalaxysource                           as egalaxysource,
        giftedpurchase                          as is_gifted_purchase,

        -- Network
        remoteaddress                           as remote_address,
        serveraddress                           as server_address,

        -- Misc
        translationlanguageid                   as translation_language_id,
        personalmessageid                       as personal_message_id,
        securetoken                             as secure_token,
        recordversion                           as record_version,
        lastupdatedby                           as last_updated_by,

        -- Dates
        try_to_timestamp(orderdate)             as order_date,
        try_to_timestamp(lastupdate)            as last_updated_at,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
