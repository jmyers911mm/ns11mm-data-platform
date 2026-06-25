{% macro create_raw_streams() %}

{% set raw_tables = [
    'RAW_SALESFORCE_NPS_CONTACT',
    'RAW_SALESFORCE_NPS_ACCOUNT',
    'RAW_SALESFORCE_NPS_OPPORTUNITY',
    'RAW_SALESFORCE_NPS_CAMPAIGN',
    'RAW_SALESFORCE_NPS_TASK',
    'RAW_SALESFORCE_MC_TRACKING_SENT',
    'RAW_SALESFORCE_MC_TRACKING_OPEN',
    'RAW_SALESFORCE_MC_TRACKING_CLICK',
    'RAW_SALESFORCE_MC_TRACKING_BOUNCE',
    'RAW_SALESFORCE_MC_TRACKING_UNSUBSCRIBE',
    'RAW_SALESFORCE_MC_SUBSCRIBERS',
    'RAW_GATEWAY_TRANSACTIONS',
    'RAW_GATEWAY_RESERVATIONS',
    'RAW_GATEWAY_TICKETTYPES',
    'RAW_GATEWAY_CUSTOMERS',
    'RAW_GATEWAY_SESSIONS',
    'RAW_COUNTERPOINT_TRANSACTIONS',
    'RAW_COUNTERPOINT_LINEITEMS',
    'RAW_COUNTERPOINT_CUSTOMERS',
    'RAW_COUNTERPOINT_ITEMS',
    'RAW_SHOPIFY_ORDERS',
    'RAW_SHOPIFY_CUSTOMERS',
    'RAW_SHOPIFY_PRODUCTS',
    'RAW_SHOPIFY_INVENTORY',
    'RAW_CLASSY_CAMPAIGNS',
    'RAW_CLASSY_TRANSACTIONS',
    'RAW_CLASSY_DONORS',
    'RAW_BLACKBAUD_NXT_ACCOUNTS',
    'RAW_BLACKBAUD_NXT_JOURNALENTRIES',
    'RAW_BLACKBAUD_NXT_TRANSACTIONS',
    'RAW_GA4_SESSIONREPORT',
    'RAW_GOOGLE_ADS_CAMPAIGNPERFORMANCE',
    'RAW_META_ADS_CAMPAIGNINSIGHTS'
] %}

{% for table_name in raw_tables %}
  {% set stream_name = table_name | replace('RAW_', 'STREAM_') %}
  {% set sql %}
    CREATE STREAM IF NOT EXISTS {{ target.database }}.RAW.{{ stream_name }}
      ON TABLE {{ target.database }}.RAW.{{ table_name }}
      APPEND_ONLY = TRUE
      COMMENT = 'CDC stream for {{ table_name }} — append-only for incremental processing';
  {% endset %}
  {% do run_query(sql) %}
  {{ log("Created stream: " ~ stream_name, info=True) }}
{% endfor %}

{{ log("All RAW streams created. Use these for near-real-time processing.", info=True) }}

{% endmacro %}
