-- Staging model for Gateway Galaxy attribute values report view (SEED_GATE_VATTRIBUTE)
-- Co-authored with CoCo

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_vattribute') }}
),

staged as (
    select
        -- Primary key
        avgid                                   as avg_id,

        -- Facility capacity on scan
        facscapacityonscanid                    as facs_capacity_on_scan_id,
        facscapacityonscan                      as facs_capacity_on_scan,

        -- Sales program
        rdisdefsalesprogramcodeid               as dis_def_sales_program_code_id,
        rdisdefsalesprogramid                   as dis_def_sales_program_id,
        rdisdefsalesprogram                     as dis_def_sales_program,

        -- Event shift destination
        fevtshiftdestinationcodeid              as evt_shift_destination_code_id,
        fevtshiftdestinationid                  as evt_shift_destination_id,
        fevtshiftdestination                    as evt_shift_destination,

        -- Event open sales channel
        fevtopensaleschannelcodeid              as evt_open_sales_channel_code_id,
        fevtopensaleschannelid                  as evt_open_sales_channel_id,
        fevtopensaleschannel                    as evt_open_sales_channel,

        -- Event shift minutes
        fevtshiftminutescodeid                  as evt_shift_minutes_code_id,
        fevtshiftminutesid                      as evt_shift_minutes_id,
        fevtshiftminutes                        as evt_shift_minutes,

        -- Event misc
        fevttakemax                             as evt_take_max,
        fevtprevisitcomtemplateid               as evt_pre_visit_com_template_id,
        fevtsupresscommunicationid              as evt_suppress_communication_id,
        fevtsupresscommunication                as evt_suppress_communication,

        -- Event peak status
        revtpeakstatusid                        as evt_peak_status_id,
        revtpeakstatus                          as evt_peak_status,

        -- Event meeting reference
        revtmeetingreferenceid                  as evt_meeting_reference_id,
        revtmeetingreference                    as evt_meeting_reference,

        -- Item force quantity zero
        fitmforcequantityzeroid                 as itm_force_quantity_zero_id,
        fitmforcequantityzero                   as itm_force_quantity_zero,

        -- Item invoice on scan
        fitminvoiceonscanid                     as itm_invoice_on_scan_id,
        fitminvoiceonscan                       as itm_invoice_on_scan,

        -- Item date transfer
        fitmdatetransferid                      as itm_date_transfer_id,
        fitmdatetransfer                        as itm_date_transfer,

        -- Item ticket date to order
        fitmticketdatetoorderid                 as itm_ticket_date_to_order_id,
        fitmticketdatetoorder                   as itm_ticket_date_to_order,

        -- Access evergreen
        racsevergreenid                         as acs_evergreen_id,
        racsevergreen                           as acs_evergreen,

        -- Access dynamic channel
        racsdynamicchannelid                    as acs_dynamic_channel_id,
        racsdynamicchannel                      as acs_dynamic_channel,
        racsdynamicsubchannelid                 as acs_dynamic_sub_channel_id,
        racsdynamicsubchannel                   as acs_dynamic_sub_channel,

        -- Access dynamic demographic
        racsdynamicdemographicid                as acs_dynamic_demographic_id,
        racsdynamicdemographic                  as acs_dynamic_demographic,
        racsdynamicsubdemographicid             as acs_dynamic_sub_demographic_id,
        racsdynamicsubdemographic               as acs_dynamic_sub_demographic,

        -- Access dynamic product
        racsdynamicproductid                    as acs_dynamic_product_id,
        racsdynamicproduct                      as acs_dynamic_product,
        racsdynamicsubproductid                 as acs_dynamic_sub_product_id,
        racsdynamicsubproduct                   as acs_dynamic_sub_product,

        -- COA fee type / account type
        rcoafeetypeid                           as coa_fee_type_id,
        rcoafeetype                             as coa_fee_type,
        rcoaaccounttypeid                       as coa_account_type_id,
        rcoaaccounttype                         as coa_account_type,

        -- Customer issuing agency
        rcstissuingagencycodeid                 as cst_issuing_agency_code_id,
        rcstissuingagencyid                     as cst_issuing_agency_id,
        rcstissuingagency                       as cst_issuing_agency,

        -- Event program title
        revtprogramtitleid                      as evt_program_title_id,
        revtprogramtitle                        as evt_program_title,

        -- Item special
        ritmspecialid                           as itm_special_id,
        ritmspecial                             as itm_special,

        -- Item recognize basis
        ritmrecognizebasisid                    as itm_recognize_basis_id,
        ritmrecognizebasis                      as itm_recognize_basis,
        ritmrecognizedescr                      as itm_recognize_descr,

        -- Item customer basis
        ritmcustomerbasisid                     as itm_customer_basis_id,
        ritmcustomerbasis                       as itm_customer_basis,
        ritmdefaultcustomercodeid               as itm_default_customer_code_id,
        ritmdefaultcustomerid                   as itm_default_customer_id,
        ritmdefaultcustomer                     as itm_default_customer,
        ritmdefcustovrdid                       as itm_def_cust_ovrd_id,
        ritmdefcustovrd                         as itm_def_cust_ovrd,

        -- Item price point
        ritmpricepointid                        as itm_price_point_id,
        ritmpricepoint                          as itm_price_point,

        -- Item complimentary type
        ritmcomplimentarytypeid                 as itm_complimentary_type_id,
        ritmcomplimentarytype                   as itm_complimentary_type,

        -- Item product
        ritmproductid                           as itm_product_id,
        ritmproduct                             as itm_product,
        ritmsubproductid                        as itm_sub_product_id,
        ritmsubproduct                          as itm_sub_product,

        -- Item matrix code
        ritmmatrixcodeid                        as itm_matrix_code_id,
        ritmmatrixcode                          as itm_matrix_code,

        -- Node license / active / subagency
        rnodlicensenumberid                     as nod_license_number_id,
        rnodlicensenumber                       as nod_license_number,
        rnodactiveid                            as nod_active_id,
        rnodactive                              as nod_active,
        rnodsubagencyid                         as nod_sub_agency_id,
        rnodsubagency                           as nod_sub_agency,

        -- Order transport / bus / group
        rordtransporttypeid                     as ord_transport_type_id,
        rordtransporttype                       as ord_transport_type,
        rordbuscompanyid                        as ord_bus_company_id,
        rordbuscompany                          as ord_bus_company,
        rordgroupleadernameid                   as ord_group_leader_name_id,
        rordgroupleadername                     as ord_group_leader_name,

        -- Order advertising / program
        rordadvertisingcodeid                   as ord_advertising_code_id,
        rordadvertisingcode                     as ord_advertising_code,
        rordprogramnameid                       as ord_program_name_id,
        rordprogramname                         as ord_program_name,

        -- Order grade / special needs
        rordgradelevelid                        as ord_grade_level_id,
        rordgradelevel                          as ord_grade_level,
        rordspecialneedsid                      as ord_special_needs_id,
        rordspecialneeds                        as ord_special_needs,

        -- Reservation language / capacity / location
        rreslanguageid                          as res_language_id,
        rreslanguage                            as res_language,
        rreshidecapacityid                      as res_hide_capacity_id,
        rreshidecapacity                        as res_hide_capacity,
        rreslocationid                          as res_location_id,
        rreslocation                            as res_location,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
