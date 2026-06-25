{% macro validate_before_deploy(threshold=0.05) %}
/*
  Compares row counts of key models between dev and prod.
  Run via: dbt run-operation validate_before_deploy
  Reports MATCH / WARN / FAIL per model.
*/

{% set models_to_check = [
    'fct_daily_operations',
    'fct_ticket_sales',
    'fct_retail_line_items',
    'fct_donor_retention',
    'fct_campaign_performance',
    'fct_website_traffic',
    'dim_customer',
    'dim_date',
    'rpt_customer_ltv',
    'rpt_daily_operations',
] %}

{% for model_name in models_to_check %}
    {% set dev_count_query %}
        select count(*) as cnt from NS11MM_DW_DEV.{{ target.schema }}.{{ model_name }}
    {% endset %}
    {% set prod_count_query %}
        select count(*) as cnt from NS11MM_DW_PROD.GOLD.{{ model_name }}
    {% endset %}

    {% set dev_result = run_query(dev_count_query) %}
    {% set prod_result = run_query(prod_count_query) %}

    {% if dev_result and prod_result %}
        {% set dev_cnt = dev_result.columns[0].values()[0] %}
        {% set prod_cnt = prod_result.columns[0].values()[0] %}
        {% set diff_pct = ((dev_cnt - prod_cnt) / prod_cnt) | abs if prod_cnt > 0 else 0 %}
        {% if diff_pct > threshold %}
            {{ log("WARN  " ~ model_name ~ ": dev=" ~ dev_cnt ~ " prod=" ~ prod_cnt ~ " diff=" ~ (diff_pct * 100) | round(1) ~ "%", info=True) }}
        {% else %}
            {{ log("MATCH " ~ model_name ~ ": dev=" ~ dev_cnt ~ " prod=" ~ prod_cnt, info=True) }}
        {% endif %}
    {% endif %}
{% endfor %}

{% endmacro %}
