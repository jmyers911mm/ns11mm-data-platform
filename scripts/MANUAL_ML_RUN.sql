-- Rebuild ML_TICKET_DEMAND_FEATURES and run forecast model

/***
-- Step 1: Rebuild fct_ticket_availability (incremental table is empty, force full refresh)
CREATE OR REPLACE TABLE NS11MM_DW_DEV.MARTS.FCT_TICKET_AVAILABILITY AS
WITH inventory AS (
    SELECT * FROM NS11MM_DW_DEV.INTERMEDIATE.INT_TICKET_INVENTORY
),
date_attrs AS (
    SELECT date_key, day_of_week_name, day_of_week, is_weekend, month_name, year_number
    FROM NS11MM_DW_DEV.MARTS.DIM_DATE
)
SELECT
    i.inventory_key                                         AS availability_key,
    i.entry_date,
    d.day_of_week_name                                      AS day_name,
    d.day_of_week                                           AS day_of_week_num,
    d.is_weekend,
    d.month_name,
    d.year_number,
    i.entry_window_start,
    i.entry_window_end,
    i.ticket_type_id                                        AS ticket_type,
    i.ticket_capacity,
    i.tickets_reserved,
    i.tickets_available,
    i.utilization_pct,
    i.demand_level,
    i.is_override,
    CURRENT_TIMESTAMP()                                     AS _loaded_at
FROM inventory i
LEFT JOIN date_attrs d ON i.entry_date = d.date_key;

-- Step 2: Rebuild ML_TICKET_DEMAND_FEATURES
CREATE OR REPLACE TABLE NS11MM_DW_DEV.ML_FEATURES.ML_TICKET_DEMAND_FEATURES AS
WITH daily_demand AS (
    SELECT entry_date, ticket_type,
           SUM(tickets_reserved)    AS daily_reserved,
           SUM(ticket_capacity)     AS daily_capacity,
           ROUND(SUM(tickets_reserved)::FLOAT / NULLIF(SUM(ticket_capacity),0) * 100, 2) AS daily_utilization_pct,
           COUNT(CASE WHEN demand_level = 'Sold Out'                       THEN 1 END) AS windows_sold_out,
           COUNT(CASE WHEN demand_level IN ('Sold Out','High Demand')      THEN 1 END) AS windows_high_demand,
           COUNT(*)                 AS total_windows
    FROM NS11MM_DW_DEV.MARTS.FCT_TICKET_AVAILABILITY
    GROUP BY entry_date, ticket_type
),
with_features AS (
    SELECT d.*, dd.day_of_week AS day_of_week_num, dd.day_of_week_name AS day_name,
           dd.is_weekend, dd.month_of_year AS month_num, dd.year_number,
           LAG(d.daily_reserved, 1) OVER (PARTITION BY d.ticket_type ORDER BY d.entry_date) AS reserved_lag_1d,
           LAG(d.daily_reserved, 7) OVER (PARTITION BY d.ticket_type ORDER BY d.entry_date) AS reserved_lag_7d,
           AVG(d.daily_reserved) OVER (PARTITION BY d.ticket_type ORDER BY d.entry_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS reserved_7d_avg,
           AVG(d.daily_reserved) OVER (PARTITION BY d.ticket_type ORDER BY d.entry_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS reserved_30d_avg,
           STDDEV(d.daily_reserved) OVER (PARTITION BY d.ticket_type ORDER BY d.entry_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS reserved_30d_stddev
    FROM daily_demand d
    LEFT JOIN NS11MM_DW_DEV.MARTS.DIM_DATE dd ON d.entry_date = dd.date_key
)
SELECT
    entry_date AS visit_date,
    ticket_type,
    daily_reserved AS daily_visitors,
    daily_capacity,
    daily_utilization_pct,
    windows_sold_out,
    windows_high_demand,
    total_windows,
    day_of_week_num,
    day_name,
    is_weekend,
    month_num,
    year_number,
    reserved_lag_1d,
    reserved_lag_7d,
    reserved_7d_avg,
    reserved_30d_avg,
    reserved_30d_stddev,
    CURRENT_TIMESTAMP() AS _feature_computed_at
FROM with_features;

-- Step 3: Verify data is populated
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT ticket_type) AS series_count,
       MIN(visit_date) AS min_date, MAX(visit_date) AS max_date
FROM NS11MM_DW_DEV.ML_FEATURES.ML_TICKET_DEMAND_FEATURES;
***/

-- Step 3b: Create aggregated training view (single series: total daily demand, historical only)
CREATE OR REPLACE VIEW NS11MM_DW_DEV.ML_FEATURES.ML_TICKET_DEMAND_FEATURES_FILTERED AS
SELECT
    VISIT_DATE,
    SUM(DAILY_VISITORS) AS DAILY_VISITORS
FROM NS11MM_DW_DEV.ML_FEATURES.ML_TICKET_DEMAND_FEATURES
WHERE VISIT_DATE <= CURRENT_DATE()
GROUP BY VISIT_DATE;

-- Step 4: Create the forecast model (single-series: aggregate daily ticket demand)
CREATE OR REPLACE SNOWFLAKE.ML.FORECAST NS11MM_DW_DEV.ML_FEATURES.ns11mm_ticket_demand_model (
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'NS11MM_DW_DEV.ML_FEATURES.ML_TICKET_DEMAND_FEATURES_FILTERED'),
    TIMESTAMP_COLNAME => 'VISIT_DATE',
    TARGET_COLNAME => 'DAILY_VISITORS',
    CONFIG_OBJECT => {
        'on_error': 'skip',
        'evaluate': true
    }
);

-- Step 5: Generate 90-day forecast
CALL NS11MM_DW_DEV.ML_FEATURES.ns11mm_ticket_demand_model!FORECAST(
    FORECASTING_PERIODS => 90,
    CONFIG_OBJECT => {'prediction_interval': 0.95}
);

-- Step 6: Save forecast results to a table
CREATE OR REPLACE TABLE NS11MM_DW_DEV.ML_FEATURES.TICKET_DEMAND_FORECAST_90D AS
SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- Step 7: View the forecast
SELECT
    TS AS forecast_date,
    FORECAST AS predicted_daily_visitors,
    LOWER_BOUND AS lower_95,
    UPPER_BOUND AS upper_95
FROM NS11MM_DW_DEV.ML_FEATURES.TICKET_DEMAND_FORECAST_90D
ORDER BY TS;
