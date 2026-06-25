{% test hashdiff_integrity(model, column_name, key_column) %}

with null_check as (
    select count(*) as null_count
    from {{ model }}
    where {{ column_name }} is null
),

collision_check as (
    select count(*) as collision_count
    from (
        select {{ column_name }}, count(distinct {{ key_column }}) as key_count
        from {{ model }}
        group by {{ column_name }}
        having count(distinct {{ key_column }}) > 1
    ) collisions
),

combined as (
    select null_count, 0 as collision_count from null_check
    union all
    select 0 as null_count, collision_count from collision_check
)

select sum(null_count) as total_nulls, sum(collision_count) as total_collisions
from combined
having sum(null_count) > 0 or sum(collision_count) > 0

{% endtest %}
