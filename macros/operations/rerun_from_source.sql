{% macro rerun_from_source(source_name) %}
/*
  Maps a source group (models/raw/sources.yml) to its staging models and logs
  the dbt command that rebuilds them plus everything downstream.
  Live ingestion is seed-based: three source groups land in RAW and are read
  by the stg_ models listed here.
  Run via: dbt run-operation rerun_from_source --args '{"source_name": "gateway_seed"}'
*/

{% set source_map = {
    'gateway_seed': [
        'stg_gateway__acps',
        'stg_gateway__coa',
        'stg_gateway__disbursementdetails',
        'stg_gateway__facility',
        'stg_gateway__items',
        'stg_gateway__jnldetails',
        'stg_gateway__jnlheaders',
        'stg_gateway__jnlitems',
        'stg_gateway__jnltickets',
        'stg_gateway__orderlines',
        'stg_gateway__orders',
        'stg_gateway__rmevents',
        'stg_gateway__tickets',
        'stg_gateway__usage',
        'stg_gateway__vattribute',
        'stg_gateway__vusage',
    ],
    'counterpoint_seed': [
        'stg_counterpoint__imitem',
        'stg_counterpoint__pstkthist',
        'stg_counterpoint__pstkthistlin',
        'stg_counterpoint__vitkthist',
        'stg_counterpoint__vitkthistlin',
    ],
    'report_estate_seed': [
        'stg_budget__daily_scan',
        'stg_budget__retail',
        'stg_counterpoint__todays_retail',
        'stg_counterpoint__todays_retail_product',
        'stg_dpr__daily_metrics_wide',
        'stg_ecommerce__website_recurring',
        'stg_gateway__passes_by_hour',
        'stg_sensource__attendance',
        'stg_sensource__visitors',
        'stg_shopify__cost_values',
        'stg_shopify__discounts',
        'stg_shopify__orders',
        'stg_wifi__audience',
    ],
} %}

{% if source_name in source_map %}
    {% set stg_models = source_map[source_name] %}
    {{ log("Staging models for source group '" ~ source_name ~ "':", info=True) }}
    {% for model in stg_models %}
        {{ log("  " ~ model, info=True) }}
    {% endfor %}
    {% set selector = (stg_models | join('+ ')) ~ '+' %}
    {{ log("Rebuild them and everything downstream with:", info=True) }}
    {{ log("  dbt build --select " ~ selector, info=True) }}
{% else %}
    {{ log("Unknown source group: '" ~ source_name ~ "'. Valid groups: " ~ source_map.keys() | join(', '), info=True) }}
{% endif %}

{% endmacro %}
