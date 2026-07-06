{% macro gdpr_anonymize(email) %}

{%- if not email -%}
    {{ exceptions.raise_compiler_error("Required argument 'email' not provided. Usage: dbt run-operation gdpr_anonymize --args '{email: user@example.com}'") }}
{%- endif -%}

{%- set email_lower = email | lower | trim -%}
{%- set anon_hash = "SHA2('" ~ email_lower ~ "', 256)" -%}
{%- set anon_email = "'REDACTED_' || LEFT(" ~ anon_hash ~ ", 8) || '@anonymized.invalid'" -%}
{%- set anon_name = "'GDPR Redacted'" -%}
{%- set anon_phone = "'REDACTED_' || LEFT(" ~ anon_hash ~ ", 8) || '@phone.invalid'" -%}

{% set tables_affected = [] %}

{# --- Create erasure log if not exists --- #}
{% set log_sql %}
    CREATE TABLE IF NOT EXISTS {{ target.database }}.{{ target.schema }}.GDPR_ERASURE_LOG (
        request_id VARCHAR DEFAULT UUID_STRING(),
        email_hash VARCHAR,
        requested_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
        executed_at TIMESTAMP_LTZ,
        tables_affected ARRAY,
        rows_affected NUMBER,
        executed_by VARCHAR DEFAULT CURRENT_USER()
    );
{% endset %}
{% do run_query(log_sql) %}

{# --- INTERMEDIATE: int_sf_crm --- #}
{% set int_crm_sql %}
    UPDATE {{ target.database }}.INTERMEDIATE.SILVER_SF_CRM
    SET
        first_name = {{ anon_name }},
        last_name = {{ anon_name }},
        full_name = {{ anon_name }},
        email = {{ anon_email }},
        phone = {{ anon_phone }}
    WHERE LOWER(TRIM(email)) = '{{ email_lower }}';
{% endset %}
{% set result = run_query(int_crm_sql) %}
{{ log("GDPR Anonymization: Updated INTERMEDIATE.SILVER_SF_CRM", info=True) }}
{% do tables_affected.append('INTERMEDIATE.SILVER_SF_CRM') %}

{# --- INTERMEDIATE: int_pos_tickets --- #}
{% set int_tickets_sql %}
    UPDATE {{ target.database }}.INTERMEDIATE.SILVER_POS_TICKETS
    SET
        customer_email = {{ anon_email }},
        customer_phone = {{ anon_phone }}
    WHERE LOWER(TRIM(customer_email)) = '{{ email_lower }}';
{% endset %}
{% set result = run_query(int_tickets_sql) %}
{{ log("GDPR Anonymization: Updated INTERMEDIATE.SILVER_POS_TICKETS", info=True) }}
{% do tables_affected.append('INTERMEDIATE.SILVER_POS_TICKETS') %}

{# --- INTERMEDIATE: int_pos_retail --- #}
{% set int_retail_sql %}
    UPDATE {{ target.database }}.INTERMEDIATE.SILVER_POS_RETAIL
    SET
        customer_email = {{ anon_email }},
        customer_phone = {{ anon_phone }}
    WHERE LOWER(TRIM(customer_email)) = '{{ email_lower }}';
{% endset %}
{% set result = run_query(int_retail_sql) %}
{{ log("GDPR Anonymization: Updated INTERMEDIATE.SILVER_POS_RETAIL", info=True) }}
{% do tables_affected.append('INTERMEDIATE.SILVER_POS_RETAIL') %}

{# --- INTERMEDIATE: int_sf_marketing_cloud --- #}
{% set int_mc_sql %}
    UPDATE {{ target.database }}.INTERMEDIATE.SILVER_SF_MARKETING_CLOUD
    SET
        email_address = {{ anon_email }}
    WHERE LOWER(TRIM(email_address)) = '{{ email_lower }}';
{% endset %}
{% set result = run_query(int_mc_sql) %}
{{ log("GDPR Anonymization: Updated INTERMEDIATE.SILVER_SF_MARKETING_CLOUD", info=True) }}
{% do tables_affected.append('INTERMEDIATE.SILVER_SF_MARKETING_CLOUD') %}

{# --- INTERMEDIATE: int_shopify --- #}
{% set int_shopify_sql %}
    UPDATE {{ target.database }}.INTERMEDIATE.SILVER_SHOPIFY
    SET
        customer_email = {{ anon_email }},
        customer_phone = {{ anon_phone }}
    WHERE LOWER(TRIM(customer_email)) = '{{ email_lower }}';
{% endset %}
{% set result = run_query(int_shopify_sql) %}
{{ log("GDPR Anonymization: Updated INTERMEDIATE.SILVER_SHOPIFY", info=True) }}
{% do tables_affected.append('INTERMEDIATE.SILVER_SHOPIFY') %}

{# --- MARTS: dim_customer --- #}
{% set dim_customer_sql %}
    UPDATE {{ target.database }}.MARTS.DIM_CUSTOMER
    SET
        full_name = {{ anon_name }},
        first_name = {{ anon_name }},
        last_name = {{ anon_name }},
        primary_email = {{ anon_email }},
        primary_phone = {{ anon_phone }},
        emails = ARRAY_CONSTRUCT({{ anon_email }}),
        phones = ARRAY_CONSTRUCT({{ anon_phone }})
    WHERE LOWER(TRIM(primary_email)) = '{{ email_lower }}';
{% endset %}
{% set result = run_query(dim_customer_sql) %}
{{ log("GDPR Anonymization: Updated MARTS.DIM_CUSTOMER", info=True) }}
{% do tables_affected.append('MARTS.DIM_CUSTOMER') %}

{# --- MARTS: fct_ticket_sales --- #}
{% set fct_tickets_sql %}
    UPDATE {{ target.database }}.MARTS.FCT_TICKET_SALES
    SET
        customer_email = {{ anon_email }},
        customer_phone = {{ anon_phone }}
    WHERE LOWER(TRIM(customer_email)) = '{{ email_lower }}';
{% endset %}
{% set result = run_query(fct_tickets_sql) %}
{{ log("GDPR Anonymization: Updated MARTS.FCT_TICKET_SALES", info=True) }}
{% do tables_affected.append('MARTS.FCT_TICKET_SALES') %}

{# --- MARTS: rpt_member_360 --- #}
{% set rpt_360_sql %}
    UPDATE {{ target.database }}.MARTS.RPT_MEMBER_360
    SET
        full_name = {{ anon_name }},
        primary_email = {{ anon_email }},
        primary_phone = {{ anon_phone }}
    WHERE LOWER(TRIM(primary_email)) = '{{ email_lower }}';
{% endset %}
{% set result = run_query(rpt_360_sql) %}
{{ log("GDPR Anonymization: Updated MARTS.RPT_MEMBER_360", info=True) }}
{% do tables_affected.append('MARTS.RPT_MEMBER_360') %}

{# --- MARTS: rpt_customer_ltv --- #}
{% set rpt_ltv_sql %}
    UPDATE {{ target.database }}.MARTS.RPT_CUSTOMER_LTV
    SET
        full_name = {{ anon_name }},
        primary_email = {{ anon_email }},
        primary_phone = {{ anon_phone }}
    WHERE LOWER(TRIM(primary_email)) = '{{ email_lower }}';
{% endset %}
{% set result = run_query(rpt_ltv_sql) %}
{{ log("GDPR Anonymization: Updated MARTS.RPT_CUSTOMER_LTV", info=True) }}
{% do tables_affected.append('MARTS.RPT_CUSTOMER_LTV') %}

{# --- Log the erasure --- #}
{% set log_entry_sql %}
    INSERT INTO {{ target.database }}.{{ target.schema }}.GDPR_ERASURE_LOG
        (email_hash, executed_at, tables_affected)
    SELECT
        SHA2('{{ email_lower }}', 256),
        CURRENT_TIMESTAMP(),
        ARRAY_CONSTRUCT({% for t in tables_affected %}'{{ t }}'{% if not loop.last %}, {% endif %}{% endfor %});
{% endset %}
{% do run_query(log_entry_sql) %}

{{ log("", info=True) }}
{{ log("═══════════════════════════════════════════════════════════", info=True) }}
{{ log("  GDPR ERASURE COMPLETE", info=True) }}
{{ log("  Email (hashed): " ~ email_lower[:3] ~ "***@" ~ email_lower.split('@')[1] if '@' in email_lower else email_lower[:3] ~ "***", info=True) }}
{{ log("  Tables updated: " ~ tables_affected | length, info=True) }}
{{ log("  Affected tables: " ~ tables_affected | join(', '), info=True) }}
{{ log("  Logged to: GDPR_ERASURE_LOG", info=True) }}
{{ log("═══════════════════════════════════════════════════════════", info=True) }}
{{ log("", info=True) }}
{{ log("  NOTE: Run 'dbt run -s dim_customer+ --full-refresh' if downstream", info=True) }}
{{ log("        models need to reflect the anonymization.", info=True) }}

{% endmacro %}
