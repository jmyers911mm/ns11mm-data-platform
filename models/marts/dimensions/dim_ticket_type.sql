-- Marts dimension: dim_ticket_type — ticket / pass / tour / merch item classification
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing
-- Grain: one row per item_id (Gateway PLU/item catalog entry)
--
-- Classifies each ticket/pass/tour/merchandise item with derived item_type
-- and pricing context.
--
-- Source: stg_gateway__items

{{ config(materialized='table', tags=['daily', 'critical']) }}

with items as (
    select * from {{ ref('stg_gateway__items') }}
)

select
    item_id                             as ticket_type_key,
    item_id,
    plu,
    trim(item_name)                     as item_name,
    trim(description)                   as item_description,
    category,
    subcategory,
    access_code,
    price,
    cost,
    stock_type,
    pass_kind,
    event_type,
    case
        when pass_kind > 0                              then 'Pass'
        when event_type is not null and event_type != '' then 'Event'
        when stock_type = 1                             then 'Merchandise'
        when plu like '%GTO%' or plu like '%TOUR%'      then 'Tour'
        else 'Ticket'
    end                                 as item_type,
    case when status_code = 0 then true else false end as is_active,
    current_timestamp()                 as _loaded_at
from items
