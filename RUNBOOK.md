# Runbook — NS11MM Data Platform

## Daily operations

### Morning health check (run by 09:00 AM EST)

```sql
-- 1. Check pipeline log — all sources should show 'success' from overnight run
SELECT source_system, source_object, status, records_landed, run_at
FROM NS11MM_DW_DEV.RAW.PIPELINE_LOG
WHERE run_at >= DATEADD('hour', -12, CURRENT_TIMESTAMP())
ORDER BY run_at DESC;

-- 2. Check dbt run status (review GitHub Actions for last run)
-- Expected: all models PASS, zero ERRORs

-- 3. Spot-check key Gold models
SELECT MAX(visit_date) AS latest_date, COUNT(*) AS row_count
FROM NS11MM_DW_PROD.MARTS.FCT_DAILY_OPERATIONS;
```

### Pipeline failure response

1. Check `RAW.PIPELINE_LOG` for error_message
2. Check Azure Function App logs in Azure Portal → func-ns11mm-<source>-dev → Monitor
3. If auth error → regenerate credentials in source system and update Key Vault
4. If Snowflake error → check `NS11MM_DW_DEV.RAW.PIPELINE_LOG` for SQL error detail
5. Rerun pipeline manually: connect to Azure Function App and trigger manually, or run `python pipeline.py --full` locally if credentials are available

### dbt model failure response

1. Check GitHub Actions for failing step and error message
2. Run `dbt run-operation smart_retry` to identify failed models
3. Fix the issue in a feature branch
4. Run `dbt run -s <failed_model>+` in personal dev database to confirm fix
5. PR to main — CI will validate before merge

## Contacts and escalation

| Issue | Primary | Escalate to |
|---|---|---|
| Pipeline / Azure infrastructure | Kenny (IT) | Jeremy Myers |
| dbt model failures | Kalea Ramsey | Jeremy Myers |
| Snowflake account issues | Jeremy Myers | Michael Cartier (CIO) |
| Salesforce credentials | Salesforce Admin | Jeremy Myers |
| Power BI / reporting | Jeremy Myers | Domain owners |

## Quick reference

| Task | Command |
|---|---|
| Run all models | `dbt run` |
| Run specific model + downstream | `dbt run -s my_model+` |
| Run tests | `dbt test` |
| Slim CI (modified only) | `dbt build -s 'state:modified+' --defer --state ./state` |
| Validate before deploy | `dbt run-operation validate_before_deploy` |
| Compare model to prod | `dbt run-operation compare_model_to_prod --args '{"model_name": "fct_ticket_sales"}'` |
| Create ticket forecast | `dbt run-operation create_ticket_demand_forecast` |
| Sync verified queries | `dbt run-operation sync_verified_queries` |
| Full refresh a model | `dbt run -s my_model --full-refresh` |
| GDPR erasure | `dbt run-operation gdpr_anonymize --args '{email: user@example.com}'` |
| Apply governance tags | `dbt run-operation apply_governance_tags` |
| Apply masking policies | `dbt run-operation apply_masking_policies` |
| Create RAW CDC streams | `dbt run-operation create_raw_streams` |
| **Suspend all alerts** | `CALL NS11MM_DW_DEV.MONITORING.MANAGE_ALERTS('SUSPEND', 'ALL')` |
| **Resume all alerts** | `CALL NS11MM_DW_DEV.MONITORING.MANAGE_ALERTS('RESUME', 'ALL')` |
| **Suspend one alert** | `CALL NS11MM_DW_DEV.MONITORING.MANAGE_ALERTS('SUSPEND', 'ALERT_DBT_RUN_FAILURES')` |
| Execute deployed dbt project | `EXECUTE DBT PROJECT NS11MM_DW_DEV.PUBLIC.NS11MM_DATA_PLATFORM ARGS = 'build'` |
