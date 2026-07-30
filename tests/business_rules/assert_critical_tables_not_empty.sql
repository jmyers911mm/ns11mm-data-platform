-- Test (business_rule): critical fact / feature tables are non-empty after a build
-- Severity: error — an empty critical table is a build failure

{% set critical_tables = [
    'fct_daily_operations',
    'fct_daily_performance',
    'fct_daily_scan',
    'fct_retail_daily',
    'fct_retail_performance',
    'fct_today_sales_hourly',
    'fct_ticket_availability',
    'fct_ticket_demand_forecast',
    'fct_budget_dpr_forecasts',
    'fct_budget_admissions_forecasts',
    'fct_budget_retail_forecasts',
    'ml_ticket_demand_features',
    'ml_visitor_forecast_training',
    'int_pos_tickets',
    'int_ticket_scans'
] %}

{% for table in critical_tables %}
select '{{ table }}' as table_name, count(*) as row_count
from {{ ref(table) }}
having count(*) = 0
{{ "union all" if not loop.last }}
{% endfor %}
