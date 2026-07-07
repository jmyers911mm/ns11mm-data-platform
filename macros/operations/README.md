# Operations Macros

Run-operation macros for deployment, governance, ML forecasting, GDPR compliance, and incident recovery.

| Macro | Command | Purpose |
|---|---|---|
| `create_ticket_demand_forecast` | `dbt run-operation create_ticket_demand_forecast` | Creates Snowflake ML FORECAST model for 90-day ticket demand (target-aware: uses `target.database`) |
| `sync_verified_queries` | `dbt run-operation sync_verified_queries` | Lists/validates verified queries — **inactive:** the `analyses/verified_queries/` dir was removed in 1.3.1 |
| `validate_before_deploy` | `dbt run-operation validate_before_deploy` | Compares dev/prod row counts before deployment |
| `compare_model_to_prod` | `dbt run-operation compare_model_to_prod --args '{"model_name": "fct_ticket_sales"}'` | Deep single-model diff between dev and prod |
| `smart_retry` | `dbt run-operation smart_retry` | Identifies failed models and suggests rerun commands |
| `rerun_from_source` | `dbt run-operation rerun_from_source --args '{"source_table": "RAW_GATEWAY_TRANSACTIONS"}'` | Maps RAW table to downstream models |
| `resolve_quarantine` | `dbt run-operation resolve_quarantine --args '{"model_name": "silver_pos_tickets"}'` | Marks quarantined rows as resolved |
| `gdpr_anonymize` | `dbt run-operation gdpr_anonymize --args '{email: user@example.com}'` | GDPR right-to-erasure: anonymizes PII across all layers with audit log |
| `apply_masking_policies` | `dbt run-operation apply_masking_policies` | Applies MASK_NAME/EMAIL/PHONE to PII columns (runs automatically on-run-end) |
| `apply_governance_tags` | `dbt run-operation apply_governance_tags` | Applies SENSITIVITY/DATA_DOMAIN/DATA_OWNER tags (runs automatically on-run-end) |
| `create_raw_streams` | `dbt run-operation create_raw_streams` | Creates append-only CDC streams on all RAW tables |

## Notes

- `create_ticket_demand_forecast` now resolves the training table and model location from `target.database` (dev vs prod). It includes a row-count guard that raises an error if the training table is empty.
- For manual ML model training (bypassing dbt timeout), use `MANUAL_ML_RUN.sql` which filters to series with 10+ data points.

## Automatic on-run-end hooks

The following macros run automatically after every `dbt run` or `dbt build` (non-dev targets only):
- `apply_governance_tags()` — ensures all tables have correct sensitivity and domain tags
- `apply_masking_policies()` — ensures PII columns have masking policies attached
