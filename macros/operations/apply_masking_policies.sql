{% macro apply_masking_policies() %}

{#-
    Applies column masking policies to every ACTIVE model that carries direct
    identifiers. Target list rebuilt 2026-07-29 from the live model set (the
    previous list referenced pre-rename POC objects and disabled models, so
    the existence check made the whole macro a silent no-op).

    Keep this list in sync with docs/architecture/DATA_CLASSIFICATION.md —
    that doc's PII inventory and this macro must name the same objects.

    Policies (MASK_NAME / MASK_EMAIL / MASK_PHONE) are created outside this
    repo, in <policy_db>.PUBLIC. The policy database follows the target
    database by default; override with --vars 'masking_policy_database: ...'
    if policies live centrally.

    object_type matters: staging/intermediate/report models are VIEWS and
    need ALTER VIEW; dims/facts are TABLES.
-#}

{%- set policy_db = var('masking_policy_database', target.database) -%}

{% set pii_columns = [
    {'schema': 'STAGING', 'table': 'STG_WIFI__AUDIENCE', 'type': 'VIEW', 'columns': [
        ('EMAIL_ADDRESS', 'MASK_EMAIL'), ('FIRST_NAME', 'MASK_NAME'), ('LAST_NAME', 'MASK_NAME')
    ]},
    {'schema': 'STAGING', 'table': 'STG_ECOMMERCE__WEBSITE_RECURRING', 'type': 'VIEW', 'columns': [
        ('EMAIL', 'MASK_EMAIL')
    ]},
    {'schema': 'INTERMEDIATE', 'table': 'INT_POS_TICKETS', 'type': 'VIEW', 'columns': [
        ('CUSTOMER_EMAIL', 'MASK_EMAIL')
    ]},
    {'schema': 'MARTS', 'table': 'DIM_CUSTOMER', 'type': 'TABLE', 'columns': [
        ('CUSTOMER_NAME', 'MASK_NAME')
    ]},
    {'schema': 'MARTS', 'table': 'RPT_WIFI_EMAIL_EXPORT', 'type': 'VIEW', 'columns': [
        ('EMAIL_ADDRESS', 'MASK_EMAIL'), ('FIRST_NAME', 'MASK_NAME'), ('LAST_NAME', 'MASK_NAME')
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
        ALTER {{ tbl['type'] }} {{ target.database }}.{{ tbl['schema'] }}.{{ tbl['table'] }}
          MODIFY COLUMN {{ col_name }}
          SET MASKING POLICY {{ policy_db }}.PUBLIC.{{ policy_name }} FORCE;
      {% endset %}
      {% do run_query(sql) %}
    {% endfor %}
    {{ log("Applied masking to " ~ tbl['schema'] ~ "." ~ tbl['table'], info=True) }}
  {% else %}
    {{ log("Masking SKIPPED (object/column not found): " ~ tbl['schema'] ~ "." ~ tbl['table'], info=True) }}
  {% endif %}
{% endfor %}

{{ log("Masking policies: done.", info=True) }}

{% endmacro %}
