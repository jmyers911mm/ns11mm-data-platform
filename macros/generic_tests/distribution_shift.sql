{% test distribution_shift(model, column_name, value, min_pct=0.0, max_pct=1.0) %}

with counts as (
    select
        count(*) as total,
        sum(case when {{ column_name }} = '{{ value }}' then 1 else 0 end) as value_count
    from {{ model }}
),

pct as (
    select
        case when total = 0 then 0
             else value_count / total::float
        end as value_pct
    from counts
)

select value_pct
from pct
where value_pct < {{ min_pct }}
   or value_pct > {{ max_pct }}

{% endtest %}
