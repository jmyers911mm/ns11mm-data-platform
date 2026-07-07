-- Staging model for Gateway Galaxy tickets (SEED_GATE_TICKETS)
-- Co-authored with CoCo

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_tickets') }}
),

staged as (
    select
        -- Primary key
        ticketid                                as ticket_id,

        -- Ticket identifiers
        visualid                                as visual_id,
        accesscode                              as access_code,
        id                                      as barcode_id,
        ticketguid                              as ticket_guid,
        externalid                              as external_id,

        -- Transaction context
        nodeno                                  as node_no,
        transno                                 as trans_no,
        linenum                                 as line_num,
        serial                                  as serial_no,
        orderno                                 as order_no,
        eventno                                 as event_no,

        -- Product / pricing
        tktcode                                 as ticket_code,
        plu                                     as plu,
        productno                               as product_no,
        fkeyno                                  as function_key_no,
        qty                                     as quantity,
        tktindex                                as ticket_index,
        price                                   as price,
        tax                                     as tax,
        taxes                                   as tax_flags,
        commission                              as commission,
        remainingvalue                           as remaining_value,
        upgradevalue                             as upgrade_value,

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

        -- Dates
        try_to_timestamp(datesold)              as sold_at,
        try_to_timestamp(endoflifedate)         as ticket_date,
        try_to_timestamp(lastuse)               as last_use_at,
        try_to_timestamp(expiration)            as expires_at,
        try_to_timestamp(activatebydate)        as activate_by_date,
        try_to_timestamp(lastupdate)            as last_updated_at,

        -- Customer
        customerid                              as customer_id,
        trim(custno)                            as customer_no,
        contactid                               as contact_id,
        firstname                               as first_name,
        lastname                                as last_name,

        -- Channel and delivery
        saleschannelid                          as sales_channel_id,
        deliverymethodid                        as delivery_method_id,

        -- Flags and misc
        company                                 as company_id,
        galaxysiteid                            as galaxy_site_id,
        capacityid                              as capacity_id,
        preprinted                              as is_preprinted,
        duplicate                               as is_duplicate,
        reprinted                               as is_reprinted,
        guestphotorequired                      as guest_photo_required,
        acct                                    as account_code,
        taxmethods                              as tax_methods,
        updatecode                              as update_code,
        pictureid                               as picture_id,
        pricetoken                              as price_token,
        reprintonnextscan                       as reprint_on_next_scan,
        endoflifedatestatus                     as end_of_life_date_status,
        endoflifelockwindow                     as end_of_life_lock_window,
        requirespassownerscan                   as requires_pass_owner_scan,
        waiverstatus                            as waiver_status,
        attributevaluegroupid                   as attribute_value_group_id,
        recordversion                           as record_version,
        lastupdatedby                           as last_updated_by,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
qualify row_number() over (partition by ticket_id order by _loaded_at desc) = 1
