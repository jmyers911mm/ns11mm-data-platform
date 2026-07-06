-- Staging model for Gateway Galaxy ticket usage/scans (SEED_GATE_USAGE)
-- Co-authored with CoCo

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_usage') }}
),

staged as (
    select
        -- Primary key
        usageid                                 as usage_id,
        usageguid                               as usage_guid,

        -- Ticket reference
        visualid                                as visual_id,
        scannedvisualid                         as scanned_visual_id,
        accesscode                              as access_code,
        idno                                    as id_no,
        serialno                                as serial_no,

        -- Access point / facility
        acp                                     as acp_id,
        facilityid                              as facility_id,
        attractionid                            as attraction_id,

        -- Usage details
        code                                    as code,
        status                                  as status_code,
        originalstatus                          as original_status,
        usagecondition                          as usage_condition,
        qty                                     as quantity,
        useno                                   as use_no,
        points                                  as points,
        entrymethod                             as entry_method,
        override                                as is_override,
        operationid                             as operation_id,

        -- Entitlement / bank
        entitlementcharged                      as entitlement_charged,
        bankcharged                             as bank_charged,
        bankno                                  as bank_no,

        -- Biometric / external
        biometricstatus                         as biometric_status,
        externalusage                           as is_external_usage,
        processingerror                         as processing_error,
        acsreservationconfirmationnumber        as acs_reservation_confirmation_no,

        -- Operator / site
        operator                                as operator_id,
        galaxysiteid                            as galaxy_site_id,
        originalusageid                         as original_usage_id,

        -- Audit
        recordversion                           as record_version,
        lastupdatedby                           as last_updated_by,

        -- Dates
        try_to_timestamp(usetime)               as use_time,
        try_to_timestamp(lastupdate)            as last_updated_at,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
