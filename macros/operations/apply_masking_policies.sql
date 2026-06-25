{% macro apply_masking_policies() %}

{%- set policy_db = 'NS11MM_DW_DEV' -%}

{% set pii_columns = [
    {'schema': 'MARTS', 'table': 'DIM_CUSTOMER', 'columns': [
        ('FULL_NAME', 'MASK_NAME'), ('FIRST_NAME', 'MASK_NAME'), ('LAST_NAME', 'MASK_NAME'),
        ('PRIMARY_EMAIL', 'MASK_EMAIL'), ('PRIMARY_PHONE', 'MASK_PHONE')
    ]},
    {'schema': 'MARTS', 'table': 'RPT_MEMBER_360', 'columns': [
        ('FULL_NAME', 'MASK_NAME'), ('PRIMARY_EMAIL', 'MASK_EMAIL'), ('PRIMARY_PHONE', 'MASK_PHONE')
    ]},
    {'schema': 'MARTS', 'table': 'RPT_CUSTOMER_LTV', 'columns': [
        ('FULL_NAME', 'MASK_NAME'), ('PRIMARY_EMAIL', 'MASK_EMAIL'), ('PRIMARY_PHONE', 'MASK_PHONE')
    ]},
    {'schema': 'MARTS', 'table': 'FCT_TICKET_SALES', 'columns': [
        ('CUSTOMER_EMAIL', 'MASK_EMAIL'), ('CUSTOMER_PHONE', 'MASK_PHONE')
    ]},
    {'schema': 'INTERMEDIATE', 'table': 'SILVER_SF_CRM', 'columns': [
        ('FULL_NAME', 'MASK_NAME'), ('FIRST_NAME', 'MASK_NAME'), ('LAST_NAME', 'MASK_NAME'),
        ('EMAIL', 'MASK_EMAIL'), ('PHONE', 'MASK_PHONE')
    ]},
    {'schema': 'INTERMEDIATE', 'table': 'SILVER_POS_TICKETS', 'columns': [
        ('CUSTOMER_EMAIL', 'MASK_EMAIL'), ('CUSTOMER_PHONE', 'MASK_PHONE')
    ]},
    {'schema': 'INTERMEDIATE', 'table': 'SILVER_POS_RETAIL', 'columns': [
        ('CUSTOMER_EMAIL', 'MASK_EMAIL'), ('CUSTOMER_PHONE', 'MASK_PHONE')
    ]},
    {'schema': 'INTERMEDIATE', 'table': 'SILVER_SF_MARKETING_CLOUD', 'columns': [
        ('EMAIL_ADDRESS', 'MASK_EMAIL')
    ]},
    {'schema': 'INTERMEDIATE', 'table': 'SILVER_SHOPIFY', 'columns': [
        ('CUSTOMER_EMAIL', 'MASK_EMAIL'), ('CUSTOMER_PHONE', 'MASK_PHONE')
    ]}
] %}

{% for tbl in pii_columns %}
  {% set check_sql %}
    SELECT COUNT(*) as cnt FROM {{ target.database }}.INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = '{{ tbl['schema'] }}' AND TABLE_NAME = '{{ tbl['table'] }}'
    AND COLUMN_NAME = '{{ tbl['columns'][0][0] }}'
  {% endset %}
  {% set result = run_query(check_sql) %}
  {% if result and result.rows[0][0] > 0 %}
    {% for col_name, policy_name in tbl['columns'] %}
      {% set sql %}
        ALTER TABLE {{ target.database }}.{{ tbl['schema'] }}.{{ tbl['table'] }}
          MODIFY COLUMN {{ col_name }}
          SET MASKING POLICY {{ policy_db }}.PUBLIC.{{ policy_name }} FORCE;
      {% endset %}
      {% do run_query(sql) %}
    {% endfor %}
    {{ log("Applied masking to " ~ tbl['schema'] ~ "." ~ tbl['table'], info=True) }}
  {% endif %}
{% endfor %}

{{ log("Masking policies: done.", info=True) }}

{% endmacro %}
