{% macro smart_retry() %}
/*
  Reads audit log, identifies failed models, suggests exact rerun commands.
  Run via: dbt run-operation smart_retry
*/

{% set failed_models_query %}
    select model_name, error_message, run_timestamp
    from {{ target.database }}.INTERMEDIATE.DBT_RUN_AUDIT_LOG
    where status = 'error'
      and run_timestamp >= dateadd('hour', -24, current_timestamp())
    order by run_timestamp desc
{% endset %}

{% set results = run_query(failed_models_query) %}
{% if results and results.rows | length > 0 %}
    {{ log("=== Failed models in last 24h ===", info=True) }}
    {% for row in results %}
        {{ log("FAILED: " ~ row[0] ~ " — " ~ row[1], info=True) }}
        {{ log("  Rerun: dbt run -s " ~ row[0] ~ " --full-refresh", info=True) }}
    {% endfor %}
{% else %}
    {{ log("No failed models in the last 24 hours.", info=True) }}
{% endif %}

{% endmacro %}
