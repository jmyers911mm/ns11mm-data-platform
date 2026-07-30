{% macro quarantine_failed_rows(model_name, reason) %}
    insert into {{ target.database }}.INTERMEDIATE.QUARANTINE_LOG (
        quarantine_timestamp,
        source_model,
        reason,
        row_data
    )
    select
        current_timestamp() as quarantine_timestamp,
        '{{ model_name }}' as source_model,
        '{{ reason }}' as reason,
        object_construct(*) as row_data
    from {{ ref(model_name) }}
    where {{ caller() }}
{% endmacro %}
