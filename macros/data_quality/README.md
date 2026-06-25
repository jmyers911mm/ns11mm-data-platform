# Data Quality Macros

| Macro | Purpose |
|---|---|
| `generate_hashdiff` | MD5 hash over business columns with null-safe concatenation |

| `quarantine_failed_rows` | Routes failing rows to INTERMEDIATE.QUARANTINE_LOG |
>>>>>>> remote
| `auto_heal_duplicates` | CTE wrapper that deduplicates on primary key keeping latest row |
| `check_source_freshness` | Per-source staleness thresholds; call in on-run-start |

## Freshness thresholds


All 14 source systems land into `NS11MM_DW_DEV.RAW`. Freshness SLAs are defined in `docs/DATA_CONTRACTS.yml`:
>>>>>>> remote

- **Critical (3-4 hours):** Salesforce NPS, Salesforce MC, Shopify, GA4, Classy
- **High (6 hours):** Gateway, CounterPoint
- **Medium (8 hours):** Blackbaud, Vena, Google Ads, Meta Ads

>>>>>>> remote