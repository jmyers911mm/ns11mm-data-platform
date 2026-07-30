-- Marts dimension: dim_access_code — admission-type classification for Gateway access codes
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing
-- Grain: one row per access_code value
--
-- Classifies the ~36 access codes into admission type categories. These codes
-- control which facility a ticket grants entry to.
--
-- Source: stg_gateway__tickets (distinct access_code) + stg_gateway__items (name lookup)

{{ config(materialized='table', tags=['daily', 'critical']) }}

with ticket_codes as (
    select
        access_code,
        count(*)                    as ticket_count
    from {{ ref('stg_gateway__tickets') }}
    where access_code is not null
    group by access_code
),

item_names as (
    select distinct
        access_code,
        first_value(item_name) over (
            partition by access_code order by item_id
        ) as access_code_name
    from {{ ref('stg_gateway__items') }}
    where access_code is not null
)

select
    t.access_code                       as access_code_key,
    t.access_code                       as access_code_id,
    coalesce(i.access_code_name, 'Unknown') as access_code_name,
    case
        when t.access_code in (4001, 4080, 4010)           then 'Museum General'
        when t.access_code in (10, 11, 14, 15, 16, 17, 18, 19, 20) then 'Memorial'
        when t.access_code between 308458000 and 308459000 then 'CityPass'
        when t.access_code in (4101, 4100, 4102)           then 'Tour'
        when t.access_code in (2400, 2402, 2500)           then 'Pass/Membership'
        when t.access_code in (4301)                       then 'Education'
        when t.access_code in (4003, 4002)                 then 'Museum Special'
        when t.access_code in (1150, 1011, 1021)           then 'Audio Guide'
        when t.access_code in (9997, 9998)                 then 'Admin/Test'
        else 'Other'
    end                                 as admission_type,
    t.ticket_count,
    true                                as is_active,
    current_timestamp()                 as _loaded_at
from ticket_codes t
left join item_names i on t.access_code = i.access_code
