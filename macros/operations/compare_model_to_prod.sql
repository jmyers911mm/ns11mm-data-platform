{% macro compare_model_to_prod(model_name) %}
/*
  Deep single-model comparison between dev and prod using MINUS.
  Detects new rows, lost rows, and modified rows.
  Run via: dbt run-operation compare_model_to_prod --args '{"model_name": "fct_ticket_sales"}'
*/

{% set new_rows_query %}
    select 'NEW IN DEV' as status, count(*) as row_count
    from (
        select * from NS11MM_DW_DEV.{{ target.schema }}.{{ model_name }}
        minus
        select * from NS11MM_DW_PROD.MARTS.{{ model_name }}
    )
{% endset %}

{% set lost_rows_query %}
    select 'LOST FROM PROD' as status, count(*) as row_count
    from (
        select * from NS11MM_DW_PROD.MARTS.{{ model_name }}
        minus
        select * from NS11MM_DW_DEV.{{ target.schema }}.{{ model_name }}
    )
{% endset %}

{% set new_result = run_query(new_rows_query) %}
{% set lost_result = run_query(lost_rows_query) %}

{{ log("=== Model Comparison: " ~ model_name ~ " ===", info=True) }}
{% if new_result %}
    {{ log("New rows in dev:   " ~ new_result.columns[1].values()[0], info=True) }}
{% endif %}
{% if lost_result %}
    {% set lost_cnt = lost_result.columns[1].values()[0] %}
    {{ log("Lost rows (prod → dev): " ~ lost_cnt, info=True) }}
    {% if lost_cnt | int > 0 %}
        {{ log("⚠️  DATA LOSS RISK: prod rows would be removed on deploy", info=True) }}
    {% endif %}
{% endif %}

{% endmacro %}
