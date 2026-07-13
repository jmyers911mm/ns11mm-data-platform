-- Bronze staging: Gateway (Galaxy) chart of accounts
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (finance mapping)
-- Grain:  one row per coa_id (dedup: latest _loaded_at wins)
--
-- Conforms seed_gate_coa, the Galaxy chart of accounts used to classify journal
-- lines. Joined in the int_gateway__*_journal_lines models to attach account
-- context to ticket / item detail.
--
-- ADR-001: rename/recast only, no business logic (that lands in the int_ layer).

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_coa') }}
),

staged as (
    select
        -- Primary key
        coaid                                   as coa_id,
        coaguid                                 as coa_guid,

        -- Account identifiers
        accountid                               as account_id,
        glcode                                  as gl_code,
        name                                    as account_name,
        codedescr                               as code_description,
        accountkind                             as account_kind,

        -- Classification
        companyid                               as company_id,
        category                                as category,
        subcat                                  as subcategory,

        -- Behavior
        rptaction                               as rpt_action,
        amtaction                               as amt_action,
        qtyaction                               as qty_action,

        -- Commission
        commissionrate                          as commission_rate,
        commissionkind                          as commission_kind,

        -- User codes
        usercode1                               as user_code_1,
        usercode2                               as user_code_2,
        usercode3                               as user_code_3,

        -- Status
        activeind                               as is_active,
        inactive                                as is_inactive,

        -- Misc
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
qualify row_number() over (partition by coa_id order by _loaded_at desc) = 1
