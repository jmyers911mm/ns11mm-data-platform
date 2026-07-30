# Data Quality Macros

| Macro | Purpose |
|---|---|
| `generate_hashdiff` | MD5 hash over business columns with null-safe concatenation |
| `quarantine_failed_rows` | Routes failing rows to INTERMEDIATE.QUARANTINE_LOG |
| `auto_heal_duplicates` | CTE wrapper that deduplicates on primary key keeping latest row |

> `check_source_freshness` was removed: it built queries it never executed,
> against tables that do not exist. Source freshness is checked with dbt's
> built-in `dbt source freshness`, driven by the `freshness:` blocks in
> `models/raw/sources.yml`.

## Freshness thresholds

Sources resolve to `{{ target.database }}.RAW` (your dev DB, `NS11MM_DW_DEV`,
or prod, depending on target). The live sources are the three seed-based
groups defined in `models/raw/sources.yml`:

- **`gateway_seed`** (Gateway Ticketing Galaxy export): warn after 7 days, error after 14 days
- **`counterpoint_seed`** (NCR CounterPoint POS export): warn after 7 days, error after 14 days
- **`report_estate_seed`** (report-estate 911dw tables): warn after 2 days, error after 4 days
