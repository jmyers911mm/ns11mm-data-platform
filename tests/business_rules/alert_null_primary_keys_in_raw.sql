-- Test (business_rule): raw source seeds carry no null primary keys (CSV-load guard)
-- Co-authored with CoCo
-- Severity: warn — surfaces load issues without breaking the daily build

{{ config(severity='warn') }}

{% set checks = [
    ('seed_gate_tickets', 'TICKETID'),
    ('seed_gate_orders', 'ORDERID'),
    ('seed_gate_orderlines', 'ORDERLINEID'),
    ('seed_gate_rmevents', 'EVENTID'),
    ('seed_gate_usage', 'USAGEID'),
    ('seed_gate_items', 'ITEMID')
] %}

{% for table, pk_col in checks %}
select
    '{{ table }}' as source_table,
    '{{ pk_col }}' as pk_column,
    count(*) as null_pk_count
from {{ source('gateway_seed', table) }}
where {{ pk_col }} is null
having count(*) > 0
{{ "union all" if not loop.last }}
{% endfor %}
