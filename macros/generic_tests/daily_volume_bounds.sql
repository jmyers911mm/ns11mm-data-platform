{% test daily_volume_bounds(model, date_column, min_rows=0, max_rows=1000000) %}

with daily as (
    select
        {{ date_column }}::date as run_date,
        count(*) as row_count
    from {{ model }}
    where {{ date_column }}::date = current_date - 1
    group by 1
)

select run_date, row_count
from daily
where row_count < {{ min_rows }}
   or row_count > {{ max_rows }}

{% endtest %}
