{% macro apply_governance_tags() %}

{#-
    Applies SENSITIVITY / DATA_DOMAIN / DATA_OWNER tags to the ACTIVE model
    estate. Target list rebuilt 2026-07-29 from the live model set (the
    previous list referenced pre-rename POC objects and disabled models).

    Keep in sync with docs/architecture/DATA_CLASSIFICATION.md and with
    apply_masking_policies() — every PII-tagged object here should also
    appear in the masking macro.

    Tags are created outside this repo in <tag_db>.PUBLIC. The tag database
    follows the target database by default; override with
    --vars 'governance_tag_database: ...' if tags live centrally.
-#}

{%- set tag_db = var('governance_tag_database', target.database) -%}

{% set tag_assignments = [
    {'schema': 'STAGING',      'table': 'STG_WIFI__AUDIENCE',              'sensitivity': 'PII',          'domain': 'MARKETING', 'owner': 'Jeremy Myers', 'type': 'VIEW'},
    {'schema': 'STAGING',      'table': 'STG_ECOMMERCE__WEBSITE_RECURRING','sensitivity': 'PII',          'domain': 'ECOMMERCE', 'owner': 'Jeremy Myers', 'type': 'VIEW'},
    {'schema': 'INTERMEDIATE', 'table': 'INT_POS_TICKETS',                 'sensitivity': 'PII',          'domain': 'TICKETING', 'owner': 'Jeremy Myers', 'type': 'VIEW'},
    {'schema': 'MARTS',        'table': 'DIM_CUSTOMER',                    'sensitivity': 'PII',          'domain': 'TICKETING', 'owner': 'Jeremy Myers', 'type': 'TABLE'},
    {'schema': 'MARTS',        'table': 'RPT_WIFI_EMAIL_EXPORT',           'sensitivity': 'PII',          'domain': 'MARKETING', 'owner': 'Jeremy Myers', 'type': 'VIEW'},
    {'schema': 'MARTS',        'table': 'DIM_DATE',                        'sensitivity': 'PUBLIC',       'domain': 'REFERENCE', 'owner': 'Jeremy Myers', 'type': 'TABLE'},
    {'schema': 'MARTS',        'table': 'FCT_DAILY_PERFORMANCE',           'sensitivity': 'INTERNAL',     'domain': 'FINANCE',   'owner': 'Jeremy Myers', 'type': 'TABLE'},
    {'schema': 'MARTS',        'table': 'FCT_DAILY_OPERATIONS',            'sensitivity': 'INTERNAL',     'domain': 'TICKETING', 'owner': 'Jeremy Myers', 'type': 'TABLE'},
    {'schema': 'MARTS',        'table': 'FCT_DAILY_SCAN',                  'sensitivity': 'INTERNAL',     'domain': 'ATTENDANCE','owner': 'Jeremy Myers', 'type': 'TABLE'},
    {'schema': 'MARTS',        'table': 'FCT_RETAIL_DAILY',                'sensitivity': 'INTERNAL',     'domain': 'RETAIL',    'owner': 'Jeremy Myers', 'type': 'TABLE'},
    {'schema': 'MARTS',        'table': 'FCT_RETAIL_PERFORMANCE',          'sensitivity': 'INTERNAL',     'domain': 'RETAIL',    'owner': 'Jeremy Myers', 'type': 'TABLE'},
    {'schema': 'MARTS',        'table': 'FCT_TODAY_SALES_HOURLY',          'sensitivity': 'INTERNAL',     'domain': 'RETAIL',    'owner': 'Jeremy Myers', 'type': 'TABLE'},
    {'schema': 'MARTS',        'table': 'FCT_TICKET_AVAILABILITY',         'sensitivity': 'INTERNAL',     'domain': 'TICKETING', 'owner': 'Jeremy Myers', 'type': 'TABLE'},
    {'schema': 'MARTS',        'table': 'FCT_TICKET_DEMAND_FORECAST',      'sensitivity': 'INTERNAL',     'domain': 'TICKETING', 'owner': 'Jeremy Myers', 'type': 'TABLE'},
    {'schema': 'MARTS',        'table': 'FCT_BUDGET_DPR_FORECASTS',        'sensitivity': 'CONFIDENTIAL', 'domain': 'FINANCE',   'owner': 'Jeremy Myers', 'type': 'TABLE'},
    {'schema': 'MARTS',        'table': 'FCT_BUDGET_ADMISSIONS_FORECASTS', 'sensitivity': 'CONFIDENTIAL', 'domain': 'FINANCE',   'owner': 'Jeremy Myers', 'type': 'TABLE'},
    {'schema': 'MARTS',        'table': 'FCT_BUDGET_RETAIL_FORECASTS',     'sensitivity': 'CONFIDENTIAL', 'domain': 'FINANCE',   'owner': 'Jeremy Myers', 'type': 'TABLE'},
    {'schema': 'ML_FEATURES',  'table': 'ML_TICKET_DEMAND_FEATURES',       'sensitivity': 'INTERNAL',     'domain': 'TICKETING', 'owner': 'Jeremy Myers', 'type': 'TABLE'},
    {'schema': 'ML_FEATURES',  'table': 'ML_VISITOR_FORECAST_TRAINING',    'sensitivity': 'INTERNAL',     'domain': 'ATTENDANCE','owner': 'Jeremy Myers', 'type': 'TABLE'}
] %}

{% for t in tag_assignments %}
  {% set check_sql %}
    SELECT COUNT(*) as cnt FROM {{ target.database }}.INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = '{{ t['schema'] }}' AND TABLE_NAME = '{{ t['table'] }}'
  {% endset %}
  {% set result = run_query(check_sql) %}
  {% if result and result.rows[0][0] > 0 %}
    {% set sql %}
      ALTER {{ t['type'] }} {{ target.database }}.{{ t['schema'] }}.{{ t['table'] }}
        SET TAG {{ tag_db }}.PUBLIC.SENSITIVITY = '{{ t['sensitivity'] }}',
                {{ tag_db }}.PUBLIC.DATA_DOMAIN = '{{ t['domain'] }}',
                {{ tag_db }}.PUBLIC.DATA_OWNER = '{{ t['owner'] }}';
    {% endset %}
    {% do run_query(sql) %}
  {% else %}
    {{ log("Tagging SKIPPED (object not found): " ~ t['schema'] ~ "." ~ t['table'], info=True) }}
  {% endif %}
{% endfor %}

{{ log("Governance tags applied to all existing tables.", info=True) }}

{% endmacro %}
