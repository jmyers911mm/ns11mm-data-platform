-- Bronze staging: Gateway (Galaxy) facilities / venues
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing
-- Grain:  one row per facility_id (dedup: latest _loaded_at wins)
--
-- Conforms seed_gate_facility (venue / facility catalog with capacity). Reference
-- dimension for facility attribution across the ticketing domain.
--
-- ADR-001: rename/recast only, no business logic (that lands in the int_ layer).

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_facility') }}
),

staged as (
    select
        -- Primary key
        facilityid                              as facility_id,

        -- Identifiers
        idno                                    as id_no,
        name                                    as facility_name,
        descr                                   as description,

        -- Capacity
        capacity                                as capacity,
        velocitytimelimit                       as velocity_time_limit,
        passholderscangap                       as passholder_scan_gap,

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
qualify row_number() over (partition by facility_id order by _loaded_at desc) = 1
