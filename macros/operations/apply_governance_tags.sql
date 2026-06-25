{% macro apply_governance_tags() %}

{%- set tag_db = 'NS11MM_DW_DEV' -%}

{% set tag_assignments = [
    {'schema': 'INTERMEDIATE', 'table': 'SILVER_SF_CRM', 'sensitivity': 'PII', 'domain': 'CRM', 'owner': 'Jeremy Myers'},
    {'schema': 'INTERMEDIATE', 'table': 'SILVER_POS_TICKETS', 'sensitivity': 'PII', 'domain': 'TICKETING', 'owner': 'Jeremy Myers'},
    {'schema': 'INTERMEDIATE', 'table': 'SILVER_POS_RETAIL', 'sensitivity': 'PII', 'domain': 'RETAIL', 'owner': 'Jeremy Myers'},
    {'schema': 'INTERMEDIATE', 'table': 'SILVER_SF_MARKETING_CLOUD', 'sensitivity': 'PII', 'domain': 'MARKETING', 'owner': 'Jeremy Myers'},
    {'schema': 'INTERMEDIATE', 'table': 'SILVER_SHOPIFY', 'sensitivity': 'PII', 'domain': 'RETAIL', 'owner': 'Jeremy Myers'},
    {'schema': 'INTERMEDIATE', 'table': 'SILVER_CLASSY', 'sensitivity': 'INTERNAL', 'domain': 'FUNDRAISING', 'owner': 'Jeremy Myers'},
    {'schema': 'INTERMEDIATE', 'table': 'SILVER_BLACKBAUD', 'sensitivity': 'CONFIDENTIAL', 'domain': 'FINANCE', 'owner': 'Jeremy Myers'},
    {'schema': 'INTERMEDIATE', 'table': 'SILVER_GOOGLE_ANALYTICS', 'sensitivity': 'INTERNAL', 'domain': 'WEB_ANALYTICS', 'owner': 'Jeremy Myers'},
    {'schema': 'INTERMEDIATE', 'table': 'SILVER_GOOGLE_ADS', 'sensitivity': 'INTERNAL', 'domain': 'MARKETING', 'owner': 'Jeremy Myers'},
    {'schema': 'INTERMEDIATE', 'table': 'SILVER_META_ADS', 'sensitivity': 'INTERNAL', 'domain': 'MARKETING', 'owner': 'Jeremy Myers'},
    {'schema': 'MARTS', 'table': 'DIM_CUSTOMER', 'sensitivity': 'PII', 'domain': 'CRM', 'owner': 'Jeremy Myers'},
    {'schema': 'MARTS', 'table': 'DIM_DATE', 'sensitivity': 'PUBLIC', 'domain': 'CRM', 'owner': 'Jeremy Myers'},
    {'schema': 'MARTS', 'table': 'FCT_TICKET_SALES', 'sensitivity': 'PII', 'domain': 'TICKETING', 'owner': 'Jeremy Myers'},
    {'schema': 'MARTS', 'table': 'FCT_RETAIL_LINE_ITEMS', 'sensitivity': 'INTERNAL', 'domain': 'RETAIL', 'owner': 'Jeremy Myers'},
    {'schema': 'MARTS', 'table': 'FCT_FUNDRAISING', 'sensitivity': 'INTERNAL', 'domain': 'FUNDRAISING', 'owner': 'Jeremy Myers'},
    {'schema': 'MARTS', 'table': 'FCT_DAILY_OPERATIONS', 'sensitivity': 'INTERNAL', 'domain': 'TICKETING', 'owner': 'Jeremy Myers'},
    {'schema': 'MARTS', 'table': 'RPT_MEMBER_360', 'sensitivity': 'PII', 'domain': 'CRM', 'owner': 'Jeremy Myers'},
    {'schema': 'MARTS', 'table': 'RPT_CUSTOMER_LTV', 'sensitivity': 'PII', 'domain': 'CRM', 'owner': 'Jeremy Myers'},
    {'schema': 'MARTS', 'table': 'RPT_DAILY_OPERATIONS', 'sensitivity': 'INTERNAL', 'domain': 'TICKETING', 'owner': 'Jeremy Myers'},
    {'schema': 'MARTS', 'table': 'RPT_DIGITAL_MARKETING', 'sensitivity': 'INTERNAL', 'domain': 'MARKETING', 'owner': 'Jeremy Myers'},
    {'schema': 'MARTS', 'table': 'FCT_GL_TRANSACTIONS', 'sensitivity': 'CONFIDENTIAL', 'domain': 'FINANCE', 'owner': 'Jeremy Myers'},
    {'schema': 'ML_FEATURES', 'table': 'ML_MEMBER_CHURN_FEATURES', 'sensitivity': 'INTERNAL', 'domain': 'CRM', 'owner': 'Jeremy Myers'},
    {'schema': 'ML_FEATURES', 'table': 'ML_TICKET_DEMAND_FEATURES', 'sensitivity': 'PUBLIC', 'domain': 'TICKETING', 'owner': 'Jeremy Myers'}
] %}

{% for t in tag_assignments %}
  {% set check_sql %}
    SELECT COUNT(*) as cnt FROM {{ target.database }}.INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = '{{ t['schema'] }}' AND TABLE_NAME = '{{ t['table'] }}'
  {% endset %}
  {% set result = run_query(check_sql) %}
  {% if result and result.rows[0][0] > 0 %}
    {% set sql %}
      ALTER TABLE {{ target.database }}.{{ t['schema'] }}.{{ t['table'] }}
        SET TAG {{ tag_db }}.PUBLIC.SENSITIVITY = '{{ t['sensitivity'] }}',
                {{ tag_db }}.PUBLIC.DATA_DOMAIN = '{{ t['domain'] }}',
                {{ tag_db }}.PUBLIC.DATA_OWNER = '{{ t['owner'] }}';
    {% endset %}
    {% do run_query(sql) %}
  {% endif %}
{% endfor %}

{{ log("Governance tags applied to all existing tables.", info=True) }}

{% endmacro %}
