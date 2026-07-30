{% macro validate_before_deploy(threshold=0.05) %}
/*
  Release gate: compares row counts of the critical marts between the current
  target database and NS11MM_DW_PROD.MARTS.
  Run via: dbt run-operation validate_before_deploy
  Reports MATCH / WARN per model; SKIPs a model when either side is missing
  (e.g. NS11MM_DW_PROD does not exist yet, or the model has not been built).
*/

{% set models_to_check = [
    'fct_daily_performance',
    'fct_daily_operations',
    'fct_retail_daily',
    'fct_retail_performance',
    'fct_daily_scan',
    'dim_date',
    'rpt_daily_performance_report',
    'rpt_dpr_powerbi',
    'rpt_retail_powerbi',
] %}

{# --- Check that the prod database exists before comparing against it --- #}
{% set prod_db_exists = false %}
{% if execute %}
    {% set prod_db_result = run_query("show databases like 'NS11MM_DW_PROD'") %}
    {% if prod_db_result and prod_db_result.rows | length > 0 %}
        {% set prod_db_exists = true %}
    {% endif %}
{% endif %}

{% if not prod_db_exists %}
    {{ log("SKIP  NS11MM_DW_PROD does not exist — nothing to compare against. All models skipped.", info=True) }}
{% else %}
    {% for model_name in models_to_check %}
        {% set dev_relation = adapter.get_relation(database=target.database, schema='MARTS', identifier=model_name | upper) %}
        {% set prod_relation = adapter.get_relation(database='NS11MM_DW_PROD', schema='MARTS', identifier=model_name | upper) %}

        {% if dev_relation is none %}
            {{ log("SKIP  " ~ model_name ~ ": not found in " ~ target.database ~ ".MARTS", info=True) }}
        {% elif prod_relation is none %}
            {{ log("SKIP  " ~ model_name ~ ": not found in NS11MM_DW_PROD.MARTS", info=True) }}
        {% else %}
            {% set dev_result = run_query("select count(*) as cnt from " ~ target.database ~ ".MARTS." ~ model_name) %}
            {% set prod_result = run_query("select count(*) as cnt from NS11MM_DW_PROD.MARTS." ~ model_name) %}

            {% if dev_result and prod_result %}
                {% set dev_cnt = dev_result.columns[0].values()[0] %}
                {% set prod_cnt = prod_result.columns[0].values()[0] %}
                {% set diff_pct = ((dev_cnt - prod_cnt) / prod_cnt) | abs if prod_cnt > 0 else 0 %}
                {% if dev_cnt < prod_cnt %}
                    {{ log("WARN  " ~ model_name ~ ": ROW COUNT DROP dev=" ~ dev_cnt ~ " prod=" ~ prod_cnt ~ " — prod rows would be lost on deploy", info=True) }}
                {% elif diff_pct > threshold %}
                    {{ log("WARN  " ~ model_name ~ ": dev=" ~ dev_cnt ~ " prod=" ~ prod_cnt ~ " diff=" ~ (diff_pct * 100) | round(1) ~ "%", info=True) }}
                {% else %}
                    {{ log("MATCH " ~ model_name ~ ": dev=" ~ dev_cnt ~ " prod=" ~ prod_cnt, info=True) }}
                {% endif %}
            {% endif %}
        {% endif %}
    {% endfor %}
{% endif %}

{% endmacro %}
