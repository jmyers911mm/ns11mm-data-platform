{% macro rerun_from_source(source_table) %}
/*
  Maps a RAW source table to downstream dbt models and suggests rebuild commands.
  Run via: dbt run-operation rerun_from_source --args '{"source_table": "RAW_GATEWAY_TRANSACTIONS"}'
*/

{% set source_map = {
    'RAW_GATEWAY_TRANSACTIONS':     ['stg_gateway__transactions', 'int_pos_tickets', 'fct_ticket_sales', 'fct_daily_operations'],
    'RAW_COUNTERPOINT_TRANSACTIONS': ['stg_counterpoint__transactions', 'int_pos_retail', 'fct_retail_line_items'],
    'RAW_SALESFORCE_NPS_CONTACT':   ['stg_salesforce_nps__contacts', 'int_sf_crm', 'dim_customer', 'fct_donor_retention'],
    'RAW_SALESFORCE_MC_TRACKING_SENT': ['stg_salesforce_mc__tracking', 'int_sf_marketing_cloud', 'fct_campaign_performance'],
    'RAW_SHOPIFY_ORDERS':           ['stg_shopify__orders', 'int_shopify', 'fct_retail_line_items'],
    'RAW_CLASSY_TRANSACTIONS':      ['stg_classy__transactions', 'int_classy', 'fct_fundraising'],
    'RAW_GA4_SESSIONREPORT':        ['stg_ga4__sessions', 'int_google_analytics', 'fct_website_traffic'],
} %}

{% if source_table in source_map %}
    {% set downstream = source_map[source_table] %}
    {{ log("Downstream models for " ~ source_table ~ ":", info=True) }}
    {% for model in downstream %}
        {{ log("  " ~ model, info=True) }}
    {% endfor %}
    {{ log("Suggested rerun: dbt run -s " ~ downstream | join(' '), info=True) }}
{% else %}
    {{ log("Source table not found in source map: " ~ source_table, info=True) }}
{% endif %}

{% endmacro %}
