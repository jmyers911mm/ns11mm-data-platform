{% test cardinality_change(model, column_name, min_distinct=1, max_distinct=1000000) %}

with counts as (
    select count(distinct {{ column_name }}) as distinct_count
    from {{ model }}
)

select distinct_count
from counts
where distinct_count < {{ min_distinct }}
   or distinct_count > {{ max_distinct }}

{% endtest %}
