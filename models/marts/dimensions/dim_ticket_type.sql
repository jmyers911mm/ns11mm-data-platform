/*
  dim_ticket_type
  Source: silver_pos_tickets + ref_ticket_types seed
  STATUS: Awaiting RAW data.
  Seed provides reference data; Silver provides actuals from Gateway.
*/

{{ config(materialized='table') }}

with from_silver as (
    select distinct
        ticket_type_id,
        ticket_type_id  as ticket_type_name,
        visitor_category,
        unit_price      as standard_price
    from {{ ref('silver_pos_tickets') }}
),

from_seed as (
    select
        ticket_type_id::varchar as ticket_type_id,
        ticket_type_name,
        ticket_category         as visitor_category,
        default_price           as standard_price
    from {{ ref('ref_ticket_types') }}
)

select
    coalesce(s.ticket_type_id, r.ticket_type_id)       as ticket_type_id,
    coalesce(s.ticket_type_name, r.ticket_type_name)   as ticket_type_name,
    coalesce(s.visitor_category, r.visitor_category)   as visitor_category,
    coalesce(s.standard_price, r.standard_price)       as standard_price,
    case when coalesce(s.standard_price, r.standard_price) = 0 then true else false end as is_free_admission,
    case
        when coalesce(s.visitor_category, r.visitor_category) in ('Child', 'Senior') then 'Concession'
        when coalesce(s.visitor_category, r.visitor_category) = 'Member'              then 'Membership'
        when coalesce(s.visitor_category, r.visitor_category) = 'School Group'        then 'Group'
        else 'Standard'
    end as pricing_tier,
    current_timestamp() as _loaded_at
from from_seed r
full outer join from_silver s on r.ticket_type_id = s.ticket_type_id
