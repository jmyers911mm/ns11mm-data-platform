{% macro resolve_quarantine(model_name) %}
/*
  Marks quarantined rows as resolved after a successful rerun.
  Run via: dbt run-operation resolve_quarantine --args '{"model_name": "int_pos_tickets"}'
*/

{% set resolve_query %}
    update {{ target.database }}.INTERMEDIATE.QUARANTINE_LOG
    set resolved_at = current_timestamp(),
        resolved = true
    where source_model = '{{ model_name }}'
      and resolved = false
{% endset %}

{% do run_query(resolve_query) %}
{{ log("Quarantine records resolved for model: " ~ model_name, info=True) }}

{% endmacro %}
