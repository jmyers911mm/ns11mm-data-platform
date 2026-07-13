-- Bronze staging: Gateway (Galaxy) disbursement details
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (donations / disbursement)
-- Grain:  one row per disbursement_detail_id (dedup: latest _loaded_at wins)
--
-- Conforms seed_gate_disbursementdetails, the disbursement breakdown used by the
-- DPR donations and fees logic. Joined at line grain in the enriched journal
-- intermediate models.
--
-- ADR-001: rename/recast only, no business logic (that lands in the int_ layer).

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
qualify row_number() over (partition by disbursement_detail_id order by _loaded_at desc) = 1
