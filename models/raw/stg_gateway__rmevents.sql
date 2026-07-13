-- Bronze staging: Gateway (Galaxy) resource-management events
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (timed entry)
-- Grain:  one row per event_id (null keys dropped; dedup: latest _loaded_at wins)
--
-- Conforms seed_gate_rmevents, the timed-entry / resource-managed events (start,
-- end, on/off sale, seating, capacity flags). Supplies event context to the DPR
-- fees/tour logic.
-- NOTE: start_at (source startdatetime) is null for a meaningful volume of rows,
-- which is why downstream models coalesce off it rather than trusting it.
--
-- ADR-001: rename/recast only, no business logic (that lands in the int_ layer).

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_rmevents') }}
),

staged as (
    select
        -- Primary key
        eventid                                 as event_id,
        eventguid                               as event_guid,

        -- Event details
        eventname                               as event_name,
        eventtypeid                             as event_type_id,
        eventprogramid                          as event_program_id,
        usereventnumber                         as user_event_number,
        showid                                  as show_id,

        -- Resources
        resourceid                              as resource_id,
        resourcereservationid                   as resource_reservation_id,
        nodenumber                              as node_number,
        notesid                                 as notes_id,

        -- Status flags
        activeindicator                         as is_active,
        limitindicator                          as has_limit,
        privateevent                            as is_private_event,

        -- Roster / waitlist
        hasroster                               as has_roster,
        haswaitlist                             as has_waitlist,
        waitlistcodetableid                     as waitlist_code_table_id,
        rosterattributegroupid                  as roster_attribute_group_id,

        -- Seating
        rseventseatmapid                        as rs_event_seat_map_id,
        hassequencedcapacity                    as has_sequenced_capacity,
        enableseatoptions                       as enable_seat_options,
        seatoptionstoreturn                     as seat_options_to_return,
        seatoptionspercentage                   as seat_options_percentage,
        maxseatspersession                      as max_seats_per_session,
        enablesingleseatcheck                   as enable_single_seat_check,

        -- Sales channel
        saleschannelcapacitylimitmode           as sales_channel_capacity_limit_mode,
        haseventsalelimits                      as has_event_sale_limits,

        -- Attributes
        attributevaluegroupid                   as attribute_value_group_id,

        -- Audit
        recordversion                           as record_version,
        lastupdatedby                           as last_updated_by,

        -- Dates
        try_to_timestamp(startdatetime)         as start_at,
        try_to_timestamp(enddatetime)           as end_at,
        try_to_timestamp(onsaledatetime)        as on_sale_at,
        try_to_timestamp(offsaledatetime)       as off_sale_at,
        try_to_timestamp(lastupdate)            as last_updated_at,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
where event_id is not null
qualify row_number() over (partition by event_id order by _loaded_at desc) = 1
