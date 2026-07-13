-- Bronze staging: Gateway (Galaxy) item / product catalog
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing
-- Grain:  one row per item_id (dedup: latest _loaded_at wins)
--
-- Conforms seed_gate_items, the PLU/product catalog. plu is the join key to the
-- ticket and journal tables and is trimmed at source (CHAR(20) padding) so it
-- aligns with the trimmed plu everywhere else. Supplies item_name / kind to
-- int_gateway__ticket_demand_features.
--
-- ADR-001: rename/recast only, no business logic (that lands in the int_ layer).

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_items') }}
),

staged as (
    select
        -- Primary key
        itemid                                  as item_id,

        -- Product identifiers
        -- trim: Galaxy stores plu as space-padded CHAR(20); padding defeats every
        -- downstream equality join/filter (proven 2026-07-08). Trim once at source.
        trim(plu)                               as plu,
        upc                                     as upc,
        name                                    as item_name,
        descr                                   as description,
        shortnotes                              as short_notes,

        -- Classification
        productno                               as product_no,
        levelno                                 as level_no,
        fkeyno                                  as function_key_no,
        company                                 as company_id,
        category                                as category,
        subcat                                  as subcategory,
        section                                 as section,
        kind                                    as kind,
        disbursementtype                        as disbursement_type,
        stocktype                               as stock_type,
        eventtype                               as event_type,
        eventid                                 as event_id,

        -- Pricing
        cost                                    as cost,
        price                                   as price,
        maxprice                                as max_price,
        minprice                                as min_price,
        basis                                   as price_basis,
        valuekind                               as value_kind,
        itemvalue                               as item_value,
        pricemethod                             as price_method,
        itempricemethod                         as item_price_method,
        priceedit                               as price_edit,
        priceprogramgroupid                     as price_program_group_id,

        -- Discount
        discid                                  as discount_id,
        discamt                                 as discount_amt,
        discountgroup                           as discount_group,
        allowcomp                               as allow_comp,

        -- Access / ticketing
        accesscode                              as access_code,
        passkind                                as pass_kind,
        passflag                                as pass_flag,
        passexpiration                          as pass_expiration,
        printer                                 as printer,
        tktset                                  as ticket_set,
        datespecific                             as is_date_specific,
        daterange                               as date_range,
        blockoutgroup                           as blockout_group,

        -- Upgrade / exchange
        canupgrade                              as can_upgrade,
        upgradevalue                             as upgrade_value,
        upgradecompany                          as upgrade_company,
        upgradecategory                         as upgrade_category,
        upgradesubcategory                      as upgrade_subcategory,
        exchangeid                              as exchange_id,
        exchange                                as exchange,
        adultexchangeid                         as adult_exchange_id,
        childexchangeid                         as child_exchange_id,

        -- Tax
        taxflag                                 as tax_flag,
        taxmethods                              as tax_methods,
        usetaxtable                             as use_tax_table,
        taxtableid                              as tax_table_id,
        taxtablemethod                          as tax_table_method,

        -- Delivery / fulfillment
        deliverymethodgroupid                   as delivery_method_group_id,
        serialize                               as serialize,
        suppressserial                          as suppress_serial,

        -- Rental
        resourceid                              as resource_id,
        rentalserialid                          as rental_serial_id,
        reservationrequire                      as reservation_required,
        rentalphotorequire                      as rental_photo_required,

        -- Membership / loyalty
        renewalplu                              as renewal_plu,
        replenishplu                            as replenish_plu,
        packageplu                              as package_plu,
        membersplitplu                          as member_split_plu,
        campaignid                              as campaign_id,
        fundid                                  as fund_id,
        registergift                            as register_gift,

        -- Guest fields
        contactrequired                         as contact_required,
        promptforname                           as prompt_for_name,
        promptforguestfields                    as prompt_for_guest_fields,
        guestfieldattributegroupid              as guest_field_attribute_group_id,
        guestphotoflag                          as guest_photo_flag,
        minimumage                              as minimum_age,
        maximumage                              as maximum_age,
        photoallowed                            as photo_allowed,

        -- Gift aid / donation
        giftaidtype                             as gift_aid_type,
        giftaidamount                           as gift_aid_amount,
        donationtype                            as donation_type,

        -- Activation
        requiresactivation                      as requires_activation,
        activationmethod                        as activation_method,

        -- Flags
        modifykind                              as modify_kind,
        status                                  as status_code,
        fopmask                                 as fop_mask,
        pictureflag                             as picture_flag,
        fkeyflag                                as fkey_flag,
        fkeyflag2                               as fkey_flag_2,
        itemfilter                              as item_filter,
        reasonrequire                           as reason_required,
        debittypeid                             as debit_type_id,
        suppressevent                           as suppress_event,
        externalcallid                          as external_call_id,
        maxgroupadmits                          as max_group_admits,
        suppressnamerequired                    as suppress_name_required,
        suppresscollectappealandsolicitation    as suppress_collect_appeal,
        tktreqforpurchaseitmgrpid               as tkt_req_for_purchase_item_grp_id,
        isdualjoint                             as is_dual_joint,
        islockerplu                             as is_locker_plu,
        lockerfid                               as locker_fid,
        lockersubfid                            as locker_sub_fid,
        feeplu                                  as fee_plu,

        -- Rate limits
        minrate                                 as min_rate,
        maxrate                                 as max_rate,

        -- RFID / encoding
        encodetime                              as encode_time,
        updaterfidmaps                          as update_rfid_maps,

        -- Misc
        currency                                as currency,
        accountidno                             as account_id_no,
        attributevaluegroupid                   as attribute_value_group_id,
        recordversion                           as record_version,
        lastupdatedby                           as last_updated_by,

        -- Dates
        try_to_timestamp(lastupdate)            as last_updated_at,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
qualify row_number() over (partition by item_id order by _loaded_at desc) = 1