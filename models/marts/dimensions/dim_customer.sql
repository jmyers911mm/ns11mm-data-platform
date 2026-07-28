-- Marts dimension: dim_customer — customer dimension from Gateway ticketing
-- Co-authored with CoCo
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing
-- Grain: one row per customer_id (Gateway CUSTOMERID)
--
-- Derives customer type from CUSTNO prefix patterns. Identity resolution
-- across Gateway/CounterPoint/Salesforce deferred until those CRM feeds land.
--
-- Source: stg_gateway__tickets (customer fields)

{{ config(materialized='table', tags=['daily', 'critical']) }}

with customer_tickets as (
    select
        customer_id,
        customer_no,
        first_name,
        last_name,
        min(sold_at)::date          as first_ticket_date,
        max(sold_at)::date          as last_ticket_date,
        count(*)                    as total_tickets
    from {{ ref('stg_gateway__tickets') }}
    where customer_id is not null and customer_id != 0
    group by customer_id, customer_no, first_name, last_name
)

select
    customer_id                                             as customer_key,
    customer_id                                             as gate_customer_id,
    customer_no                                             as gate_custno,
    nullif(trim(coalesce(first_name, '') || ' ' || coalesce(last_name, '')), '')
                                                            as customer_name,
    case
        when customer_no like 'WEB%'                       then 'Web'
        when customer_no like 'CIT%'                       then 'CityPass'
        when customer_no like 'V-%'                        then 'Viator'
        when customer_no like 'GOC%'                       then 'Go City'
        when customer_no like 'GET%'                       then 'GetYourGuide'
        when customer_no like 'TIQ%'                       then 'Tiqets'
        when customer_no like 'GRP%' or customer_no like 'C-D%' then 'Group'
        when customer_no like 'PRE%'                       then 'Pre-Sale'
        when customer_no like 'RID%'                       then 'Rides/Partner'
        else 'Other'
    end                                                     as customer_type,
    first_ticket_date,
    last_ticket_date,
    total_tickets,
    current_timestamp()                                     as _loaded_at
from customer_tickets
