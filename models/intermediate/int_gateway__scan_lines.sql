{{ config(materialized='view') }}

-- Silver intermediate: gate scan lines with ticket market segment
-- ---------------------------------------------------------------------------
-- Domain: attendance / scanning
-- Grain:  one row per usage (scan) event with its ticket's market category
--
-- Replaces legacy 911dw.fact_dailyscan_data (t_fact_dailyscan_data from Galaxy
-- usage). Joins each scan event to the ticket behind it via visual_id, then to
-- the ticket's matrix/attribute, to recover the MARKET CATEGORY that the Daily
-- Scan Report breaks out (CityPASS, C3, Explorer, School Groups, ...).
--
-- Scan qty = usage.quantity (scannedQty). Tickets-sold qty for the same segment
-- is the ticket quantity. Category is resolved downstream against
-- seed_scan_market_segment.
--
-- JOIN PATH (verify against live data): usage.visual_id = jnltickets.visual_id.
-- The market "category" string is derived from the ticket's sales channel /
-- matrix; here we expose the candidate keys (sales_channel, matrix_code,
-- sales_program_id) and let the segment seed map them. If the legacy category
-- came from a Galaxy market/reseller table not yet seeded, that table becomes
-- the mapping source -- flagged for confirmation.

with scans as (
    select
        usage_id,
        visual_id,
        scan_date,
        gate_id,
        visitor_count                      as scanned_qty,
        is_valid_scan
    from {{ ref('int_ticket_scans') }}
),

tickets as (
    select
        visual_id,
        plu,
        quantity                           as ticket_qty,
        sales_channel_id,
        sales_program_id,
        attribute_value_group_id
    from {{ ref('stg_gateway__jnltickets') }}
),

attr as (
    select avg_id, itm_matrix_code, acs_dynamic_channel
    from {{ ref('stg_gateway__vattribute') }}
),

joined as (
    select
        s.usage_id,
        s.scan_date                        as key_date,
        s.gate_id,
        s.is_valid_scan,
        s.scanned_qty,
        t.ticket_qty,
        t.plu,
        a.itm_matrix_code                  as matrix_code,
        a.acs_dynamic_channel              as sales_channel,
        -- Category candidate: the sales channel is the closest structured proxy
        -- for the legacy market category; the seed maps it to a segment.
        coalesce(a.acs_dynamic_channel, 'Unmapped') as category
    from scans s
    left join tickets t on s.visual_id = t.visual_id
    left join attr    a on t.attribute_value_group_id = a.avg_id
)

select * from joined