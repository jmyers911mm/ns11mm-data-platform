-- Bronze staging: Gateway (Galaxy) access control points
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing
-- Grain:  one row per acp_unique_id (dedup: latest _loaded_at wins)
--
-- Conforms seed_gate_acps, the scan gates / access control points that produce
-- the usage (scan) events. Reference source for attendance and gate attribution.
--
-- ADR-001: rename/recast only, no business logic (that lands in the int_ layer).

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_acps') }}
),

staged as (
    select
        -- Primary key
        acpuniqueid                             as acp_unique_id,

        -- Identifiers
        acpid                                   as acp_id,
        name                                    as acp_name,

        -- Location
        node                                    as node_no,
        facilityid                              as facility_id,
        exitfacilityid                          as exit_facility_id,
        attractionid                            as attraction_id,

        -- Classification
        kind                                    as kind,
        acpgroupid                              as acp_group_id,

        -- Config
        points                                  as points,
        checkpointid                            as checkpoint_id,
        layoutid                                as layout_id,
        validateguestmovements                  as validate_guest_movements,

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
qualify row_number() over (partition by acp_unique_id order by _loaded_at desc) = 1
