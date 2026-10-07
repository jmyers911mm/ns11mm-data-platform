# 5.0.0: Seeds Schema & Budget Forecasts

- **Date:** 2026-07-27
- **Version:** 5.0.0

Session date: 2026-07-27. Introduced a dedicated `SEEDS` schema, loaded three new budget/forecast
seed tables from Excel-to-CSV uploads, and fixed the DPR semantic view to remove a phantom
`DATE_ID` column. **Breaking change**: all `SEED_*` tables now live in `SEEDS` instead of `MARTS`.
Any external queries referencing `MARTS.SEED_*` must be updated.

## Added

| Object | Type | Detail |
|--------|------|--------|
| `NS11MM_DW_DEV_JMYERS.SEEDS` | Schema | New dedicated schema for all seed/lookup tables. |
| `SEED_DPR_FORECASTS` | Seed table (365 rows) | FY2026 daily DPR budget: tickets, revenue, audio, donations, ecommerce, cafe, tours. |
| `SEED_FORECASTED_VALUE_FOR_DATE` | Seed table (365 rows) | FY2026 daily admissions/attendance budget by facility: attendance, tickets, guided tours, CityPASS, memorial tours. |
| `SEED_RETAIL_FORECASTS` | Seed table (1,095 rows) | FY2026 daily retail budget by facility (3 facilities × 365 days): capture rate, visitors, conversion, profit, donations. |
| `_budget_sources.yml` | dbt source | Source definition pointing at the three new budget seeds in `SEEDS` schema. |

## Changed

| Area | Change |
|------|--------|
| `dbt_project.yml` | Seeds default schema changed from per-seed overrides to `+schema: SEEDS` for all seeds. |
| 12 existing SEED_* tables | Moved from `MARTS` to `SEEDS` schema (`ALTER TABLE … RENAME TO`). |
| DPR semantic view | Removed `primary_key` block from DP (fact) table — `DATE_ID` no longer surfaces as a selectable column. Fixed relationship join column from non-existent `DATE_ID` to actual `DATE_KEY`. Removed `FISCAL_MONTH` and `FISCAL_YEAR` dimensions (columns don't exist in `DIM_DATE`). |

## Migration notes

- **External consumers** (Power BI, ad-hoc SQL) referencing `MARTS.SEED_*` must update to `SEEDS.SEED_*`.
- **dbt models** are unaffected — they use `ref('seed_*')` which resolves via the project config.
- The 3 new budget tables were renamed from `FACT_*` → `SEED_*` to follow naming conventions.

---
