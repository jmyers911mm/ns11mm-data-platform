{% macro auto_heal_duplicates(model, primary_key, order_by='_loaded_at desc') %}
    with deduped as (
        select *,
               row_number() over (
                   partition by {{ primary_key }}
                   order by {{ order_by }}
               ) as _row_num
        from {{ model }}
    )
    select * exclude (_row_num)
    from deduped
    where _row_num = 1
{% endmacro %}
