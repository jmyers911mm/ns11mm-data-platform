-- Staging model for Gateway Galaxy usage report view (SEED_GATE_VUSAGE)
-- Co-authored with CoCo

{{ config(materialized='view') }}

with source as (
    select * from {{ source('gateway_seed', 'seed_gate_vusage') }}
),

staged as (
    select
        -- Primary key
        usageid                                 as usage_id,

        -- Ticket reference
        ticketid                                as ticket_id,
        visualid                                as visual_id,
        packagevisualid                         as package_visual_id,
        accesscode                              as access_code,

        -- Event / order
        eventid                                 as event_id,
        orderid                                 as order_id,

        -- Product
        plu                                     as plu,
        itmavgid                                as item_avg_id,
        itmdescr                                as item_description,
        acsavgid                                as acs_avg_id,
        acsdescr                                as acs_description,

        -- Location
        node                                    as node,
        facilityid                              as facility_id,
        facility                                as facility_name,
        acpid                                   as acp_id,
        acpname                                 as acp_name,

        -- Agent
        agentid                                 as agent_id,
        agent                                   as agent_name,

        -- Customer
        customerid                              as customer_id,
        customerexternalaccount                 as customer_external_account,

        -- Usage
        usecount                                as use_count,
        statusid                                as status_id,
        status                                  as status_name,
        quantity                                as quantity,

        -- Discount
        discountid                              as discount_id,
        discount                                as discount_name,
        amount                                  as amount,

        -- Dates
        try_to_timestamp(usetime)               as use_time,
        try_to_timestamp(datesold)              as sold_at,
        try_to_timestamp(lastupdate)            as last_updated_at,

        -- Metadata
        _loaded_at

    from source
)

select * from staged
