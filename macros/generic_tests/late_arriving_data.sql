{% test late_arriving_data(model, column_name, max_lag_hours=72) %}

select {{ column_name }}, _loaded_at
from {{ model }}
where _loaded_at is not null
  and {{ column_name }} is not null
  and datediff('hour', {{ column_name }}, _loaded_at) > {{ max_lag_hours }}

{% endtest %}
