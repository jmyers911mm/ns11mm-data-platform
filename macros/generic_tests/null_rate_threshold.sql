{% test null_rate_threshold(model, column_name, threshold=0.5) %}

with counts as (
    select
        count(*) as total_rows,
        sum(case when {{ column_name }} is null then 1 else 0 end) as null_rows
    from {{ model }}
),

check as (
    select
        total_rows,
        null_rows,
        case when total_rows = 0 then 0
             else null_rows / total_rows::float
        end as null_rate
    from counts
)

select null_rate
from check
where null_rate > {{ threshold }}

{% endtest %}
