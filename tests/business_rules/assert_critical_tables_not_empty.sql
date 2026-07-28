-- Test (business_rule): critical fact / feature tables are non-empty after a build
-- Co-authored with CoCo
-- Severity: error — an empty critical table is a build failure

{% set critical_tables = [
    'fct_daily_operations',
    'fct_ticket_availability',
    'fct_ticket_demand_forecast',
    'ml_ticket_demand_features',
    'int_pos_tickets',
    'int_ticket_scans'
] %}

{% for table in critical_tables %}
select '{{ table }}' as table_name, count(*) as row_count
from {{ ref(table) }}
having count(*) = 0
{{ "union all" if not loop.last }}
{% endfor %}
