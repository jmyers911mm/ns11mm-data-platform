{% test z_score_outlier(model, column_name, max_zscore=3) %}

WITH stats AS (
    SELECT
        AVG({{ column_name }}) AS mean_val,
        STDDEV({{ column_name }}) AS stddev_val
    FROM {{ model }}
    WHERE {{ column_name }} IS NOT NULL
)

SELECT {{ column_name }}
FROM {{ model }}, stats
WHERE stats.stddev_val > 0
  AND ABS(({{ column_name }} - stats.mean_val) / stats.stddev_val) > {{ max_zscore }}

{% endtest %}
