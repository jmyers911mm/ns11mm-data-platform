-- Macro to create Snowflake ML FORECAST model for 90-day ticket demand prediction
-- Co-authored with CoCo

{% macro create_ticket_demand_forecast(training_table=none, forecast_table=none) %}
/*
  Creates a Snowflake ML FORECAST model for 90-day multi-series ticket demand prediction.
  Run via: dbt run-operation create_ticket_demand_forecast

  Requires SNOWFLAKE.ML.FORECAST privilege on the Snowflake account.
*/

{% set training_table = training_table or (target.database ~ '.ML_FEATURES.ML_TICKET_DEMAND_FEATURES') %}
{% set forecast_table = forecast_table or (target.database ~ '.ML_FEATURES.TICKET_DEMAND_FORECAST_90D') %}

{% set row_check %}
    select count(*) as cnt from {{ training_table }}
{% endset %}

{% set row_count = run_query(row_check).columns[0].values()[0] %}
{% if row_count == 0 %}
    {{ log("ERROR: Training table " ~ training_table ~ " is empty. Cannot train forecast model.", info=True) }}
    {{ exceptions.raise_compiler_error("Training table " ~ training_table ~ " has 0 rows. Load data before running forecast.") }}
{% endif %}
{{ log("Training table has " ~ row_count ~ " rows. Proceeding with model creation...", info=True) }}

{% set create_model %}
    create or replace snowflake.ml.forecast {{ target.database }}.ML_FEATURES.ns11mm_ticket_demand_model (
        input_data => system$reference('table', '{{ training_table }}'),
        series_colname => 'ticket_type',
        timestamp_colname => 'visit_date',
        target_colname => 'daily_visitors',
        config_object => {
            'on_error': 'skip',
            'evaluate': true
        }
    );
{% endset %}

{% set run_forecast %}
    call {{ target.database }}.ML_FEATURES.ns11mm_ticket_demand_model!forecast(
        forecasting_periods => 90,
        config_object => {'prediction_interval': 0.95}
    );
{% endset %}

{% do run_query(create_model) %}
{% do run_query(run_forecast) %}
{{ log("Ticket demand forecast model created and 90-day forecast generated.", info=True) }}

{% endmacro %}
