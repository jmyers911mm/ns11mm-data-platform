{% macro log_test_results_to_audit(results) %}
  {#- Append every test node's outcome to an audit table so results can be
      queried for the current day and trended over time. Runs on-run-end;
      silently no-ops when the run contains no test nodes. -#}

  {% set test_rows = [] %}

  {% for result in results %}
    {% if result.node.resource_type == 'test' %}
      {% set node = result.node %}
      {% set test_name = node.name %}
      {% set test_type = 'generic' if node.test_metadata is defined and node.test_metadata else 'singular' %}

      {#- For singular tests use the folder name; for generic tests use the test method -#}
      {% set test_category = node.fqn[1] if node.fqn | length > 1 else 'uncategorized' %}

      {#- Tested model: first parent ref, if any -#}
      {% set tested_model = node.refs[0]['name'] if node.refs and node.refs | length > 0 else none %}

      {% do test_rows.append({
        'test_name':      test_name,
        'test_type':      test_type,
        'test_category':  test_category,
        'tested_model':   tested_model,
        'status':         result.status,
        'failures':       result.failures if result.failures is not none else 0,
        'execution_time': result.execution_time,
        'message':        result.message | replace("'", "''") if result.message else ''
      }) %}
    {% endif %}
  {% endfor %}

  {% if test_rows | length > 0 %}
    {% set audit_schema = target.database ~ '.' ~ 'DQ_TEST_RESULTS' %}
    {% set audit_table  = audit_schema ~ '.TEST_AUDIT_LOG' %}

    {#- Create the audit table if it doesn't exist -#}
    {% set create_sql %}
      CREATE TABLE IF NOT EXISTS {{ audit_table }} (
        invocation_id     STRING    NOT NULL,
        run_started_at    TIMESTAMP NOT NULL,
        test_name         STRING    NOT NULL,
        test_type         STRING,
        test_category     STRING,
        tested_model      STRING,
        status            STRING    NOT NULL,
        failures          INTEGER   DEFAULT 0,
        execution_time_s  FLOAT,
        message           STRING,
        target_name       STRING,
        inserted_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
      )
    {% endset %}
    {% do run_query(create_sql) %}

    {#- Build a single INSERT with UNION ALL for all test results -#}
    {% set insert_sql %}
      INSERT INTO {{ audit_table }}
        (invocation_id, run_started_at, test_name, test_type, test_category,
         tested_model, status, failures, execution_time_s, message, target_name)
      {% for row in test_rows %}
        SELECT
          '{{ invocation_id }}'                                       AS invocation_id,
          '{{ run_started_at.strftime("%Y-%m-%d %H:%M:%S") }}'::TIMESTAMP AS run_started_at,
          '{{ row.test_name }}'                                       AS test_name,
          '{{ row.test_type }}'                                       AS test_type,
          '{{ row.test_category }}'                                   AS test_category,
          {{ "'" ~ row.tested_model ~ "'" if row.tested_model else 'NULL' }} AS tested_model,
          '{{ row.status }}'                                          AS status,
          {{ row.failures }}                                          AS failures,
          {{ row.execution_time }}                                    AS execution_time_s,
          '{{ row.message }}'                                         AS message,
          '{{ target.name }}'                                         AS target_name
        {{ 'UNION ALL' if not loop.last }}
      {% endfor %}
    {% endset %}
    {% do run_query(insert_sql) %}

    {{ log("DQ audit log: " ~ test_rows | length ~ " test result(s) written to " ~ audit_table, info=True) }}
  {% endif %}

{% endmacro %}
