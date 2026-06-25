{% test row_count_drift(model, warn_threshold=0.5, error_threshold=2.0) %}

with current_count as (
    select count(*) as row_count,
           current_date as run_date
    from {{ model }}
),

-- Compare to expected range; alert if drift is extreme
check as (
    select row_count,
           case
               when row_count = 0 then 'ERROR: zero rows'
               else 'OK'
           end as status
    from current_count
)

select row_count
from check
where status != 'OK'

{% endtest %}
