-- Bronze staging: Gateway (Galaxy) journal details
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (DPR base)
-- Grain:  one row per jnl_detail_id (dedup: latest _loaded_at wins)
--
-- Conforms seed_gate_jnldetails (JnlDetails). This is the DPR base table: the
-- jnl_code_id = 101 rows carry tickets_sold and ticket_revenue, joined to
-- jnltickets / items / coa in int_gateway__ticket_journal_lines. Renames only.
--
-- ADR-001: rename/recast only, no business logic (that lands in the int_ layer).

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_jnldetails') }}
),

staged as (
    select
        -- Primary key
        jnldetailid                             as jnl_detail_id,
        jnldetailguid                           as jnl_detail_guid,

        -- Parent reference
        jnltranid                               as jnl_tran_id,

        -- Account
        accountid                               as account_id,
        jnlcodeid                               as jnl_code_id,

        -- Amounts
        qty                                     as quantity,
        amount                                  as amount,

        -- References
        reference                               as reference,
        auxtableid                              as aux_table_id,
        orderlineid                             as order_line_id,
        packagedetailid                         as package_detail_id,
        jnlcontactid                            as jnl_contact_id,

        -- Status
        activeind                               as is_active,

        -- Audit
        recordversion                           as record_version,
        createdby                               as created_by,
        lastupdatedby                           as last_updated_by,

        -- Dates
        try_to_timestamp(createdate)            as created_at,
        try_to_timestamp(lastupdate)            as last_updated_at,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
qualify row_number() over (partition by jnl_detail_id order by _loaded_at desc) = 1
