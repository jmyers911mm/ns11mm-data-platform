{% test schema_drift(model, expected_columns) %}

{% set actual_columns = adapter.get_columns_in_relation(model) | map(attribute='name') | list %}
{% set expected = expected_columns | map('upper') | list %}
{% set actual = actual_columns | map('upper') | list %}
{% set missing = expected | reject('in', actual) | list %}

{% if missing | length > 0 %}
    select '{{ missing | join(", ") }}' as missing_columns, 1 as failure
{% else %}
    select null as missing_columns, 0 as failure
    where 1 = 0
{% endif %}

{% endtest %}
