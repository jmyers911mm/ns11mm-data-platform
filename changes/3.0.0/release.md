# 3.0.0: Cortex Analyst Semantic Views

- **Date:** 2026-07-20
- **Version:** 3.0.0

Deploys **three new Cortex Analyst semantic views** to `NS11MM_DW_DEV_JMYERS.MARTS`
and downloads the existing DPR view into the workspace for version control.
Major version: these semantic views are the Cortex Analyst contract consumed by
the `JMYERS_TEST` agent and future Snowflake Intelligence surfaces.

## Added — semantic view YAML specs (`cortex_project/`)

- **`ATTENDANCE.sv.yaml`** — Attendance analytics model covering daily scan counts
  by market segment, ticket demand forecasting with presale lead-time analysis,
  and real-time ticket capacity/utilization. Tables: `FCT_DAILY_SCAN`,
  `FCT_TICKET_DEMAND_FORECAST`, `FCT_TICKET_AVAILABILITY`, `DIM_DATE`,
  `SEED_SCAN_MARKET_SEGMENT`. Includes relationships and SUM metrics.

- **`RETAIL.sv.yaml`** — Retail analytics model covering category-grain sales
  performance (net sales, profit, units, donations) and facility-grain daily
  aggregates (transactions, visitors, ecommerce orders). Tables:
  `FCT_RETAIL_PERFORMANCE`, `FCT_RETAIL_DAILY`, `DIM_DATE`, `SEED_FACILITY_AREA`.
  Includes gross margin % and revenue-per-visitor ratio metrics.

- **`FUNDRAISING_ECOM.sv.yaml`** — Fundraising & ecommerce scaffold. Dimension
  stubs (`DIM_CAMPAIGN`, `DIM_CUSTOMER`, `DIM_FUND`, `DIM_PAYMENT_METHOD`) plus
  `DIM_DATE`. Ready to expand once Salesforce/Blackbaud RAW connections are live.

- **`DPR.sv.yaml`** — Downloaded from deployed `NS11MM_DW_DEV_JMYERS.MARTS.DPR`
  semantic view for workspace version control. 48 metrics, custom instructions,
  and fiscal calendar dimensions.

- **`JMYERS_TEST.agent.yaml`** — Cortex Agent spec with `dpr_analyst` tool
  pointing to the DPR semantic view on `COMPUTE_WH`.

- **`cortex-project.yaml`** — Project manifest tracking all semantic view and
  agent artifacts with their Snowflake deployment targets.

- **`UNIFIED.sv.yaml`** — Cross-domain reconciliation surface spanning all four
  live day-grain facts against `DIM_DATE`. Curated metric subset for natural-
  language retrieval; 3 verified queries, custom instructions.

## Removed — consolidated to `cortex_project/` (single source of truth)

- `semantic_models/dpr.yaml` — replaced by `cortex_project/DPR.sv.yaml`
- `semantic_models/unified.yaml` — replaced by `cortex_project/UNIFIED.sv.yaml`
- `semantic_models/attendance.yaml` — replaced by `cortex_project/ATTENDANCE.sv.yaml`
- `semantic_models/retail.yaml` — replaced by `cortex_project/RETAIL.sv.yaml`
- `semantic_models/fundraising_ecom.yaml` — replaced by `cortex_project/FUNDRAISING_ECOM.sv.yaml`
- `semantic_models/create_dpr_semantic_view.sql` — deploy via `semantic_view_deploy` instead
- `semantic_models/create_unified_semantic_view.sql` — deploy via `semantic_view_deploy` instead

Per-metric governance metadata (MET-### IDs, owners, SLA tiers) remains in dbt
exposure `meta:` blocks. The semantic view YAML carries only the semantic
definition (expr, synonyms, descriptions, custom instructions) to avoid drift.
