{% macro create_ticket_demand_forecast(training_table='NS11MM_DW_PROD.ML_FEATURES.ML_TICKET_DEMAND_FEATURES', forecast_table='NS11MM_DW_PROD.ML_FEATURES.TICKET_DEMAND_FORECAST_90D') %}
/*
  Creates a Snowflake ML FORECAST model for 90-day multi-series ticket demand prediction.
  Run via: dbt run-operation create_ticket_demand_forecast

  Requires SNOWFLAKE.ML.FORECAST privilege on the Snowflake account.
*/

{% set create_model %}
    create or replace snowflake.ml.forecast ns11mm_ticket_demand_model (
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
    call ns11mm_ticket_demand_model!forecast(
        forecasting_periods => 90,
        config_object => {'prediction_interval': 0.95}
    );
{% endset %}

{% do run_query(create_model) %}
{% do run_query(run_forecast) %}
{{ log("Ticket demand forecast model created and 90-day forecast generated.", info=True) }}

{% endmacro %}
