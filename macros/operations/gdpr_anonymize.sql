{% macro gdpr_anonymize(email, request_id, customer_name=none) %}
{#
  ===========================================================================
  GDPR / CCPA RIGHT-TO-ERASURE  — SANCTIONED EXCEPTION TO ADR-001
  ===========================================================================
  ADR-001 declares the Bronze (RAW) layer immutable. GDPR/CCPA erasure is the
  one sanctioned, logged exception: the active PII surfaces
  (stg_wifi__audience, stg_ecommerce__website_recurring, int_pos_tickets,
  rpt_wifi_email_export) are all VIEWS — they cannot be updated. Erasure must
  therefore happen in the RAW landing tables and flow through on the next
  build:

    RAW.SEED_STAGE_ACCEPTANCE_UAP_DAILY   (WiFi captive portal — email, name)
    RAW.SEED_FACT_WEBSITE_RECURRING_DATA  (Drupal commerce — email)
    RAW.SEED_GATE_TICKETS                 (Gateway — first/last name; only when
                                           customer_name is supplied, since
                                           Gateway stores names, not emails)
    MARTS.DIM_CUSTOMER                    (table — customer_name; rebuilt from
                                           SEED_GATE_TICKETS, so the raw update
                                           above is what makes it stick)

  RUN ONLY via run-operation, with an APPROVED erasure request ID:

    dbt run-operation gdpr_anonymize --args '{
        "email": "person@example.com",
        "request_id": "DSAR-2026-001",
        "customer_name": "Jane Doe"   # optional — Gateway/dim_customer
    }'

  Every run is logged to {{ var('source_database') }}.INTERMEDIATE.GDPR_ERASURE_LOG
  (created if missing) with the request ID and the tables touched.
  ===========================================================================
#}

{%- if not email -%}
    {{ exceptions.raise_compiler_error("Required argument 'email' not provided. Usage: dbt run-operation gdpr_anonymize --args '{email: user@example.com, request_id: DSAR-2026-001}'") }}
{%- endif -%}
{%- if not request_id -%}
    {{ exceptions.raise_compiler_error("Required argument 'request_id' not provided — erasure must reference an approved GDPR/CCPA request. Usage: dbt run-operation gdpr_anonymize --args '{email: user@example.com, request_id: DSAR-2026-001}'") }}
{%- endif -%}

{%- set email_lower = email | lower | trim -%}
{%- set anon_hash = "sha2('" ~ email_lower ~ "', 256)" -%}
{%- set anon_email = "'REDACTED_' || left(" ~ anon_hash ~ ", 8) || '@anonymized.invalid'" -%}
{%- set anon_name = "'REDACTED'" -%}

{% set tables_affected = [] %}

{# --- Create erasure log if not exists --- #}
{% set log_sql %}
    create table if not exists {{ var('source_database') }}.INTERMEDIATE.GDPR_ERASURE_LOG (
        request_id varchar,
        email_hash varchar,
        requested_at timestamp_ltz default current_timestamp(),
        executed_at timestamp_ltz,
        tables_affected array,
        executed_by varchar default current_user()
    );
{% endset %}
{% do run_query(log_sql) %}

{# --- RAW: WiFi captive-portal audience (feeds stg_wifi__audience,
       rpt_wifi_email_export) --- #}
{% set wifi_sql %}
    update {{ var('source_database') }}.RAW.SEED_STAGE_ACCEPTANCE_UAP_DAILY
    set
        email_address = {{ anon_email }},
        first_name = {{ anon_name }},
        last_name = {{ anon_name }}
    where lower(trim(email_address)) = '{{ email_lower }}';
{% endset %}
{% do run_query(wifi_sql) %}
{{ log("GDPR erasure [" ~ request_id ~ "]: updated RAW.SEED_STAGE_ACCEPTANCE_UAP_DAILY", info=True) }}
{% do tables_affected.append('RAW.SEED_STAGE_ACCEPTANCE_UAP_DAILY') %}

{# --- RAW: Drupal commerce recurring orders (feeds
       stg_ecommerce__website_recurring) --- #}
{% set ecom_sql %}
    update {{ var('source_database') }}.RAW.SEED_FACT_WEBSITE_RECURRING_DATA
    set
        email = {{ anon_email }}
    where lower(trim(email)) = '{{ email_lower }}';
{% endset %}
{% do run_query(ecom_sql) %}
{{ log("GDPR erasure [" ~ request_id ~ "]: updated RAW.SEED_FACT_WEBSITE_RECURRING_DATA", info=True) }}
{% do tables_affected.append('RAW.SEED_FACT_WEBSITE_RECURRING_DATA') %}

{% if customer_name %}
{%- set name_lower = customer_name | lower | trim -%}

{# --- RAW: Gateway tickets carry names, not emails — redact by name so the
       redaction survives the nightly dim_customer rebuild --- #}
{% set gate_sql %}
    update {{ var('source_database') }}.RAW.SEED_GATE_TICKETS
    set
        firstname = {{ anon_name }},
        lastname = {{ anon_name }}
    where lower(trim(coalesce(firstname, '') || ' ' || coalesce(lastname, ''))) = '{{ name_lower }}';
{% endset %}
{% do run_query(gate_sql) %}
{{ log("GDPR erasure [" ~ request_id ~ "]: updated RAW.SEED_GATE_TICKETS", info=True) }}
{% do tables_affected.append('RAW.SEED_GATE_TICKETS') %}

{# --- MARTS: dim_customer is a table — redact in place so the erasure takes
       effect immediately, not just after the next build --- #}
{% set dim_customer_sql %}
    update {{ target.database }}.MARTS.DIM_CUSTOMER
    set
        customer_name = {{ anon_name }}
    where lower(trim(customer_name)) = '{{ name_lower }}';
{% endset %}
{% do run_query(dim_customer_sql) %}
{{ log("GDPR erasure [" ~ request_id ~ "]: updated MARTS.DIM_CUSTOMER", info=True) }}
{% do tables_affected.append('MARTS.DIM_CUSTOMER') %}
{% else %}
{{ log("GDPR erasure [" ~ request_id ~ "]: no customer_name supplied — RAW.SEED_GATE_TICKETS and MARTS.DIM_CUSTOMER skipped (Gateway stores names, not emails)", info=True) }}
{% endif %}

{# --- Log the erasure --- #}
{% set log_entry_sql %}
    insert into {{ var('source_database') }}.INTERMEDIATE.GDPR_ERASURE_LOG
        (request_id, email_hash, executed_at, tables_affected)
    select
        '{{ request_id }}',
        sha2('{{ email_lower }}', 256),
        current_timestamp(),
        array_construct({% for t in tables_affected %}'{{ t }}'{% if not loop.last %}, {% endif %}{% endfor %});
{% endset %}
{% do run_query(log_entry_sql) %}

{{ log("", info=True) }}
{{ log("GDPR ERASURE COMPLETE — request " ~ request_id, info=True) }}
{{ log("  Tables updated: " ~ tables_affected | join(', '), info=True) }}
{{ log("  Logged to: " ~ var('source_database') ~ ".INTERMEDIATE.GDPR_ERASURE_LOG", info=True) }}
{{ log("  NOTE: downstream views (stg_wifi__audience, stg_ecommerce__website_recurring,", info=True) }}
{{ log("        int_pos_tickets, rpt_wifi_email_export) reflect the RAW updates", info=True) }}
{{ log("        immediately; rebuild tables with: dbt build --select stg_wifi__audience+ stg_ecommerce__website_recurring+ dim_customer+", info=True) }}

{% endmacro %}
