{% macro create_dq_reporting_views() %}
  {#- Run manually: dbt run-operation create_dq_reporting_views
      Creates convenience views on top of the TEST_AUDIT_LOG table. -#}

  {% set audit_table = target.database ~ '.DQ_TEST_RESULTS.TEST_AUDIT_LOG' %}
  {% set schema      = target.database ~ '.DQ_TEST_RESULTS' %}

  {#- 1. Today's results — latest run only -#}
  {% set today_view %}
    CREATE OR REPLACE VIEW {{ schema }}.V_DQ_TODAY AS
    WITH latest_run AS (
      SELECT MAX(invocation_id) AS invocation_id
      FROM {{ audit_table }}
      WHERE run_started_at::DATE = CURRENT_DATE()
    )
    SELECT
      a.test_name,
      a.test_category,
      a.tested_model,
      a.status,
      a.failures,
      a.execution_time_s,
      a.message,
      a.run_started_at,
      a.target_name
    FROM {{ audit_table }} a
    JOIN latest_run lr ON a.invocation_id = lr.invocation_id
    ORDER BY
      CASE a.status WHEN 'fail' THEN 1 WHEN 'warn' THEN 2 WHEN 'error' THEN 3 ELSE 4 END,
      a.test_category,
      a.test_name
  {% endset %}
  {% do run_query(today_view) %}
  {{ log("Created view: " ~ schema ~ ".V_DQ_TODAY", info=True) }}

  {#- 2. Daily trend summary — pass/fail/warn counts per day -#}
  {% set trend_view %}
    CREATE OR REPLACE VIEW {{ schema }}.V_DQ_DAILY_TREND AS
    WITH per_run AS (
      SELECT
        run_started_at::DATE                             AS run_date,
        invocation_id,
        COUNT(*)                                         AS total_tests,
        SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) AS passed,
        SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) AS failed,
        SUM(CASE WHEN status = 'warn' THEN 1 ELSE 0 END) AS warned,
        SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) AS errored,
        target_name
      FROM {{ audit_table }}
      GROUP BY 1, 2, 8
    )
    SELECT
      run_date,
      target_name,
      COUNT(DISTINCT invocation_id)                       AS runs,
      ROUND(AVG(passed), 0)                               AS avg_passed,
      ROUND(AVG(failed), 0)                               AS avg_failed,
      ROUND(AVG(warned), 0)                               AS avg_warned,
      ROUND(AVG(errored), 0)                              AS avg_errored,
      ROUND(AVG(total_tests), 0)                          AS avg_total_tests,
      ROUND(AVG(passed) / NULLIF(AVG(total_tests), 0) * 100, 1) AS pass_rate_pct
    FROM per_run
    GROUP BY 1, 2
    ORDER BY run_date DESC
  {% endset %}
  {% do run_query(trend_view) %}
  {{ log("Created view: " ~ schema ~ ".V_DQ_DAILY_TREND", info=True) }}

  {#- 3. Frequent failures — tests that fail most often in the last 30 days -#}
  {% set frequent_failures_view %}
    CREATE OR REPLACE VIEW {{ schema }}.V_DQ_FREQUENT_FAILURES AS
    SELECT
      test_name,
      test_category,
      tested_model,
      COUNT(DISTINCT invocation_id)                                       AS run_count,
      SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END)                   AS fail_count,
      ROUND(SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END)
            / NULLIF(COUNT(DISTINCT invocation_id), 0) * 100, 1)          AS fail_rate_pct,
      MAX(CASE WHEN status = 'fail' THEN run_started_at END)              AS last_failure_at
    FROM {{ audit_table }}
    WHERE run_started_at >= DATEADD('day', -30, CURRENT_TIMESTAMP())
    GROUP BY 1, 2, 3
    HAVING fail_count > 0
    ORDER BY fail_rate_pct DESC, fail_count DESC
  {% endset %}
  {% do run_query(frequent_failures_view) %}
  {{ log("Created view: " ~ schema ~ ".V_DQ_FREQUENT_FAILURES", info=True) }}

{% endmacro %}
