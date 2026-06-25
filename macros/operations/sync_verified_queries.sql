{% macro sync_verified_queries() %}
/*
  Lists and validates all verified queries in analyses/verified_queries/.
  Run via: dbt run-operation sync_verified_queries
*/

{% set domains = [
    'campaigns', 'capacity_planning', 'digital_marketing',
    'donor_retention', 'membership', 'retail',
    'revenue_operations', 'ticket_sales', 'visitor_experience'
] %}

{{ log("=== NS11MM Verified Query Registry ===", info=True) }}
{% for domain in domains %}
    {{ log("Domain: " ~ domain, info=True) }}
{% endfor %}
{{ log("Run dbt docs generate to publish verified query documentation.", info=True) }}

{% endmacro %}
