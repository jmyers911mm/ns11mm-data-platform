{% test referential_integrity(model, column_name, to, field) %}

select child.{{ column_name }}
from {{ model }} child
left join {{ to }} parent
    on child.{{ column_name }} = parent.{{ field }}
where child.{{ column_name }} is not null
  and parent.{{ field }} is null

{% endtest %}
