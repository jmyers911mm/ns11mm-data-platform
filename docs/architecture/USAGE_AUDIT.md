# Usage Audit & Cost Management

> **Account:** om01578 (MS01467) · Azure East US  
> **Required role:** ACCOUNTADMIN (or role with APP_USAGE_VIEWER + USAGE_VIEWER)  
> **Last updated:** June 2026

---

## Quick Navigation


- [Pre-Built Monitoring Views](#pre-built-monitoring-views)
- [Daily Credit Summary](#daily-credit-summary)
>>>>>>> remote
- [Warehouse Spend](#warehouse-spend)
- [Serverless Feature Spend](#serverless-feature-spend)
- [Cortex AI Spend](#cortex-ai-spend)
- [Storage Costs](#storage-costs)
- [Query-Level Attribution](#query-level-attribution)
- [Resource Monitors](#resource-monitors)
- [Budgets](#budgets)
- [Snowsight UI](#snowsight-ui)

---


## Pre-Built Monitoring Views

These views are already created in `NS11MM_DW_DEV.MONITORING` for quick access:

```sql
-- Credit consumption by service (last 90 days)
SELECT * FROM NS11MM_DW_DEV.MONITORING.V_CREDIT_CONSUMPTION;

-- Query history with attribution (last 30 days)
SELECT * FROM NS11MM_DW_DEV.MONITORING.V_AUDIT_QUERY_HISTORY
WHERE query_tag LIKE 'dbt_ns11mm%';

-- Login history and security audit (last 90 days)
SELECT * FROM NS11MM_DW_DEV.MONITORING.V_AUDIT_LOGIN_HISTORY;

-- Manage alerts
CALL NS11MM_DW_DEV.MONITORING.MANAGE_ALERTS('SUSPEND', 'ALL');
CALL NS11MM_DW_DEV.MONITORING.MANAGE_ALERTS('RESUME', 'ALL');
```

---

## Daily Credit Summary
>>>>>>> remote

Total credits consumed across all services (warehouses, serverless, cloud services):

```sql
SELECT
    usage_date,
    service_type,
    ROUND(SUM(credits_used), 2) AS credits_used,
    ROUND(SUM(credits_billed), 2) AS credits_billed
FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY
WHERE usage_date >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY usage_date, service_type
ORDER BY usage_date DESC, credits_used DESC;
```

Billed cloud services (only the portion exceeding the 10% daily adjustment):

```sql
SELECT
    usage_date,
    credits_used_cloud_services,
    credits_adjustment_cloud_services,
    credits_used_cloud_services + credits_adjustment_cloud_services AS billed_cloud_services
FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY
WHERE usage_date >= DATEADD('month', -1, CURRENT_DATE())
  AND credits_used_cloud_services > 0
ORDER BY billed_cloud_services DESC;
```

---

## Warehouse Spend

### Credits by Warehouse (Last 30 Days)

```sql
SELECT
    warehouse_name,
    ROUND(SUM(credits_used_compute), 2) AS compute_credits,
    ROUND(SUM(credits_used_cloud_services), 2) AS cloud_services_credits,
    ROUND(SUM(credits_used), 2) AS total_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY warehouse_name
ORDER BY total_credits DESC;
```

### Hourly Consumption Patterns

```sql
SELECT
    DATE_PART('HOUR', start_time) AS hour_of_day,
    warehouse_name,
    ROUND(AVG(credits_used_compute), 4) AS avg_credits_per_hour
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE start_time >= DATEADD('day', -14, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY 1, 3 DESC;
```

### Anomaly Detection (Days Exceeding 50% Over Rolling Average)

```sql
WITH daily_wh AS (
    SELECT
        TO_DATE(start_time) AS usage_date,
        warehouse_name,
        SUM(credits_used) AS credits_used
    FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
    GROUP BY 1, 2
)
SELECT
    usage_date,
    warehouse_name,
    credits_used,
    AVG(credits_used) OVER (
        PARTITION BY warehouse_name
        ORDER BY usage_date
        ROWS 7 PRECEDING
    ) AS credits_7d_avg,
    ROUND(100.0 * ((credits_used / NULLIF(credits_7d_avg, 0)) - 1), 1) AS pct_over_avg
FROM daily_wh
QUALIFY pct_over_avg >= 50
ORDER BY pct_over_avg DESC;
```

---

## Serverless Feature Spend

### All Serverless Services (Last 30 Days)

```sql
SELECT
    service_type,
    ROUND(SUM(credits_used), 2) AS total_credits,
    MIN(start_time)::DATE AS first_usage,
    MAX(end_time)::DATE AS last_usage
FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_DATE())
  AND service_type NOT IN ('WAREHOUSE_METERING')
GROUP BY service_type
ORDER BY total_credits DESC;
```

### Serverless Tasks (dbt DAG, monitoring tasks)

```sql
SELECT
    start_time::DATE AS usage_date,
    database_name,
    schema_name,
    task_name,
    ROUND(SUM(credits_used), 4) AS credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.SERVERLESS_TASK_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2, 3, 4
ORDER BY credits_used DESC;
```

---

## Cortex AI Spend

### Cortex Agent Usage

```sql
SELECT
    start_time::DATE AS usage_date,
    agent_name,
    SUM(num_messages) AS messages,
    ROUND(SUM(credits_used), 4) AS credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AGENT_USAGE_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY usage_date DESC;
```

### Cortex Analyst Usage

```sql
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_ANALYST_USAGE_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_DATE())
ORDER BY start_time DESC;
```

### Cortex AI Functions (LLM Functions)

```sql
SELECT
    start_time::DATE AS usage_date,
    function_name,
    model_name,
    ROUND(SUM(credits_used), 4) AS credits_used,
    SUM(num_tokens) AS total_tokens
FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AI_FUNCTIONS_USAGE_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY 1, 2, 3
ORDER BY credits_used DESC;
```

### Snowflake Intelligence

```sql
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.SNOWFLAKE_INTELLIGENCE_USAGE_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_DATE())
ORDER BY start_time DESC;
```

---

## Storage Costs

### Current Storage by Database

```sql
SELECT
    usage_date,
    database_name,
    ROUND(average_database_bytes / POWER(1024, 3), 2) AS database_gb,
    ROUND(average_failsafe_bytes / POWER(1024, 3), 2) AS failsafe_gb,
    ROUND((average_database_bytes + average_failsafe_bytes) / POWER(1024, 3), 2) AS total_gb
FROM SNOWFLAKE.ACCOUNT_USAGE.DATABASE_STORAGE_USAGE_HISTORY
WHERE usage_date = (SELECT MAX(usage_date) FROM SNOWFLAKE.ACCOUNT_USAGE.DATABASE_STORAGE_USAGE_HISTORY)
ORDER BY total_gb DESC;
```

### Storage Growth Trend (Monthly)

```sql
SELECT
    DATE_TRUNC('month', usage_date) AS month,
    ROUND(AVG(storage_bytes + stage_bytes + failsafe_bytes) / POWER(1024, 4), 4) AS avg_total_tb
FROM SNOWFLAKE.ACCOUNT_USAGE.STORAGE_USAGE
WHERE usage_date >= DATEADD('month', -12, CURRENT_DATE())
GROUP BY 1
ORDER BY 1;
```

---

## Query-Level Attribution

### Top Credit-Consuming Queries (Last 7 Days)

```sql
SELECT
    query_id,
    user_name,
    warehouse_name,
    query_type,
    ROUND(credits_used_cloud_services, 4) AS cloud_credits,
    execution_time / 1000 AS exec_seconds,
    query_text
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD('day', -7, CURRENT_DATE())
  AND credits_used_cloud_services > 0
ORDER BY credits_used_cloud_services DESC
LIMIT 25;
```

### Credit Attribution by User (Last 30 Days)

```sql
SELECT
    user_name,
    warehouse_name,
    COUNT(*) AS query_count,
    ROUND(SUM(credits_used_cloud_services), 4) AS cloud_credits,
    ROUND(SUM(execution_time) / 1000 / 3600, 2) AS total_exec_hours
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_DATE())
  AND warehouse_name IS NOT NULL
GROUP BY 1, 2
ORDER BY total_exec_hours DESC;
```

### Credits by Query Tag (dbt Workloads)

```sql
SELECT
    query_tag,
    COUNT(*) AS query_count,
    ROUND(SUM(execution_time) / 1000 / 3600, 2) AS total_exec_hours,
    ROUND(SUM(credits_used_cloud_services), 4) AS cloud_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_DATE())
  AND query_tag LIKE 'dbt_museum%'
GROUP BY query_tag
ORDER BY total_exec_hours DESC;
```

---

## Resource Monitors

Create a resource monitor for dbt warehouses:

```sql
USE ROLE ACCOUNTADMIN;

CREATE RESOURCE MONITOR IF NOT EXISTS DBT_MONTHLY_MONITOR
  WITH CREDIT_QUOTA = 500
  FREQUENCY = MONTHLY
  START_TIMESTAMP = IMMEDIATELY
  TRIGGERS
    ON 75 PERCENT DO NOTIFY
    ON 90 PERCENT DO NOTIFY
    ON 100 PERCENT DO SUSPEND
    ON 110 PERCENT DO SUSPEND_IMMEDIATE;

ALTER WAREHOUSE DBT_DEV_WH SET RESOURCE_MONITOR = DBT_MONTHLY_MONITOR;
ALTER WAREHOUSE DBT_PROD_WH SET RESOURCE_MONITOR = DBT_MONTHLY_MONITOR;
```

View existing monitors:

```sql
SHOW RESOURCE MONITORS;
```

---

## Budgets

Snowflake budgets provide monthly spend tracking with threshold notifications. Unlike resource monitors, budgets cover both warehouse AND serverless consumption.

### View Account Budget Status

Navigate to **Admin → Cost Management → Budgets** in Snowsight, or:

```sql
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY
WHERE usage_date >= DATE_TRUNC('month', CURRENT_DATE())
ORDER BY usage_date;
```

### Monthly Spend Projection

```sql
WITH mtd AS (
    SELECT
        SUM(credits_used) AS credits_mtd,
        DATEDIFF('day', DATE_TRUNC('month', CURRENT_DATE()), CURRENT_DATE()) + 1 AS days_elapsed,
        DATEDIFF('day', DATE_TRUNC('month', CURRENT_DATE()), LAST_DAY(CURRENT_DATE())) + 1 AS days_in_month
    FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY
    WHERE usage_date >= DATE_TRUNC('month', CURRENT_DATE())
)
SELECT
    ROUND(credits_mtd, 2) AS credits_month_to_date,
    days_elapsed,
    days_in_month,
    ROUND(credits_mtd / days_elapsed * days_in_month, 2) AS projected_monthly_credits
FROM mtd;
```

---

## Snowsight UI

For visual exploration without writing SQL:

1. **Admin → Cost Management → Consumption** — Interactive dashboard with filters by type, service, resource, and tags
2. **Admin → Cost Management → Resource Monitors** — View/create resource monitors
3. **Admin → Cost Management → Budgets** — Monthly budget tracking with alerts

### Filter by Cost Center (Tags)

If you tag warehouses or objects with cost attribution tags:

```sql
ALTER WAREHOUSE COMPUTE_WH SET TAG cost_center = 'analytics';
ALTER WAREHOUSE DBT_PROD_WH SET TAG cost_center = 'data_engineering';
```

Then filter the Consumption dashboard by **Tags → cost_center → [value]**.

---

## Key Views Reference

| View | Schema | Covers | Latency |
|------|--------|--------|---------|
| `METERING_DAILY_HISTORY` | ACCOUNT_USAGE | All services (daily) | ~3h |
| `METERING_HISTORY` | ACCOUNT_USAGE | All services (hourly) | ~3h |
| `WAREHOUSE_METERING_HISTORY` | ACCOUNT_USAGE | Warehouse credits (hourly) | ~3h |
| `STORAGE_USAGE` | ACCOUNT_USAGE | Account-level storage | ~24h |
| `DATABASE_STORAGE_USAGE_HISTORY` | ACCOUNT_USAGE | Per-database storage | ~24h |
| `QUERY_HISTORY` | ACCOUNT_USAGE | Per-query metrics | ~45min |
| `SERVERLESS_TASK_HISTORY` | ACCOUNT_USAGE | Task credits | ~3h |
| `CORTEX_AGENT_USAGE_HISTORY` | ACCOUNT_USAGE | Agent tokens/credits | ~3h |
| `CORTEX_AI_FUNCTIONS_USAGE_HISTORY` | ACCOUNT_USAGE | LLM function credits | ~3h |
| `CORTEX_ANALYST_USAGE_HISTORY` | ACCOUNT_USAGE | Analyst messages | ~3h |

---

## Access Control for Cost Data

To grant cost visibility to non-admin users:

```sql
USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS COST_VIEWER_ROLE;

USE DATABASE SNOWFLAKE;
GRANT APPLICATION ROLE APP_USAGE_VIEWER TO ROLE COST_VIEWER_ROLE;
GRANT DATABASE ROLE USAGE_VIEWER TO ROLE COST_VIEWER_ROLE;

GRANT ROLE COST_VIEWER_ROLE TO USER <username>;
```
