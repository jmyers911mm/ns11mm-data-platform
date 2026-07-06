-- Staging model for Gateway Galaxy disbursement details (SEED_GATE_DISBURSEMENTDETAILS)
-- Co-authored with CoCo

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_disbursementdetails') }}
),

staged as (
    select
        -- Primary key
        disbursementdetailid                    as disbursement_detail_id,
        disbursementdetailguid                  as disbursement_detail_guid,

        -- Parent reference
        disbursementid                          as disbursement_id,

        -- Details
        name                                    as disbursement_name,
        price                                   as price,
        basis                                   as price_basis,
        value                                   as value,
        sequenceno                              as sequence_no,

        -- Classification
        kind                                    as kind,
        stocktype                               as stock_type,
        company                                 as company_id,
        category                                as category,
        subcategory                             as subcategory,

        -- Printing
        printerno                               as printer_no,
        ticketset                               as ticket_set,
        suppressserial                          as suppress_serial,

        -- Account / tax
        accountno                               as account_no,
        taxflag                                 as tax_flag,
        fkeyflag                                as fkey_flag,
        taxmethods                              as tax_methods,
        accesscode                              as access_code,
        usetaxtable                             as use_tax_table,
        taxtableid                              as tax_table_id,
        taxtablemethod                          as tax_table_method,

        -- Audit
        recordversion                           as record_version,
        lastupdatedby                           as last_updated_by,

        -- Dates
        try_to_timestamp(lastupdate)            as last_updated_at,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
