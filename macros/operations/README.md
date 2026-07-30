# Operations Macros

Run-operation macros for deployment, governance, ML forecasting, GDPR compliance, and incident recovery — plus model-logic macros used inside models.

| Macro | Command | Purpose |
|---|---|---|
| `create_ticket_demand_forecast` | `dbt run-operation create_ticket_demand_forecast` | Creates Snowflake ML FORECAST model for 90-day ticket demand (target-aware: uses `target.database`) |
| `sync_verified_queries` | `dbt run-operation sync_verified_queries` | Lists/validates verified queries — **inactive:** the `analyses/verified_queries/` dir was removed in 1.3.1 |
| `validate_before_deploy` | `dbt run-operation validate_before_deploy` | Release gate: compares row counts of the critical marts between the current target database and `NS11MM_DW_PROD.MARTS`; reports MATCH / WARN per model and SKIPs when either side is missing (e.g. prod DB not created yet) |
| `compare_model_to_prod` | `dbt run-operation compare_model_to_prod --args '{"model_name": "fct_daily_performance"}'` | Deep single-model diff between dev and prod (MINUS both ways: new / lost / modified rows) |
| `smart_retry` | `dbt run-operation smart_retry` | Identifies failed models from the audit log and suggests rerun commands |
| `rerun_from_source` | `dbt run-operation rerun_from_source --args '{"source_name": "gateway_seed"}'` | Maps a source group (gateway_seed / counterpoint_seed / report_estate_seed) to its staging models and logs the rebuild command |
| `resolve_quarantine` | `dbt run-operation resolve_quarantine --args '{"model_name": "int_pos_tickets"}'` | Marks quarantined rows as resolved in `INTERMEDIATE.QUARANTINE_LOG` |
| `gdpr_anonymize` | `dbt run-operation gdpr_anonymize --args '{email: user@example.com, request_id: DSAR-2026-001}'` | GDPR/CCPA right-to-erasure — the sanctioned, logged exception to ADR-001. Redacts PII in the RAW landing tables (WiFi UAP log, website recurring, Gateway tickets when `customer_name` is supplied) plus `MARTS.DIM_CUSTOMER`; every run is written to `INTERMEDIATE.GDPR_ERASURE_LOG` |
| `apply_masking_policies` | `dbt run-operation apply_masking_policies` | Applies MASK_NAME/EMAIL/PHONE to PII columns (runs automatically on-run-end) |
| `apply_governance_tags` | `dbt run-operation apply_governance_tags` | Applies SENSITIVITY/DATA_DOMAIN/DATA_OWNER tags to the active model estate (target list rebuilt 2026-07-29; runs automatically on-run-end) |
| `create_raw_streams` | `dbt run-operation create_raw_streams` | Creates append-only CDC streams on the (future) RAW landing tables |

## Model-logic macros

Not run-operations — these are called **inside models** (currently
`int_gateway__ticket_journal_lines`) to keep Galaxy business rules in one place:

| Macro | Defined in | Purpose |
|---|---|---|
| `gateway_recognized_date(va, jt, rme)` | `gateway_recognized_date.sql` | Recreates the Galaxy recognize-basis date logic (bases 182/185/349 + fallbacks); every branch coalesces to `end_of_life_date` because `rme.start_at` and `ticketdate` are unreliable in the extract |
| `gateway_general_admission_flag(va, jt, dd)` | `gateway_recognized_date.sql` | Derives `ga_flag` (general admission vs tour/other) from `disbursement_id` + matrix code `GAD%` |

## Notes

- `create_ticket_demand_forecast` resolves the training table and model location from `target.database` (dev vs prod). It includes a row-count guard that raises an error if the training table is empty.
- For manual ML model training (bypassing dbt timeout), use `MANUAL_ML_RUN.sql` which filters to series with 10+ data points.

## Automatic on-run-end hooks

The following macros run automatically after every `dbt run` or `dbt build` (non-dev targets only):
- `apply_governance_tags()` — ensures all tables have correct sensitivity and domain tags
- `apply_masking_policies()` — ensures PII columns have masking policies attached
