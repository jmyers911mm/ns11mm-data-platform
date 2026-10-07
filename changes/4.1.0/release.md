# 4.1.0: Dimension Table Buildout

- **Date:** 2026-07-22
- **Version:** 4.1.0

*Errata (2026-07-29): the `dim_marketing_channel` re-enable recorded below was later undone — the model was subsequently removed from the repo without a changelog entry (its seed `ref_marketing_channels` remains). See the Reconciliation subsection of [6.2.0].*

Session date: 2026-07-22. Started from "should we break out repeating values in SEED
tables into dedicated tables?" — cardinality analysis confirmed strong candidates and
grew into a full dimension buildout. Also cleaned up NULL-only rows from SEED tables and
moved 5 dimension models out of the disabled folder into production.

## Data Cleanup

**RAW.SEED_* NULL row removal** — Deleted 833,128 rows across 4 tables where all columns
except `_LOADED_AT` were NULL (artifact of source extraction):
- `SEED_GATE_TICKETS`: 697,752 rows
- `SEED_GATE_ORDERLINES`: 104,042 rows
- `SEED_GATE_RMEVENTS`: 29,152 rows
- `SEED_GATE_ORDERS`: 2,182 rows

## Added (net-new dimension models)

| Model | Rows | Source | Purpose |
|-------|------|--------|---------|
| `dim_access_code` | 36 | `stg_gateway__tickets` + `stg_gateway__items` | Maps ~36 access codes to admission type categories (Museum General, Memorial, CityPass, Tour, Pass/Membership, Education, Audio Guide, Admin/Test) |
| `dim_event` | 29,485 | `stg_gateway__rmevents` | Timed-entry events, tours, programs, shows with active/private/roster/waitlist flags |
| `dim_store` | 5 | `seed_retail_store_facility` + `seed_facility_area` | CounterPoint store/register → facility mapping (Museum Store, Memorial Carts, Ecommerce, Cafe) |
| `dim_coa` | 712 | `stg_gateway__coa` | Chart of Accounts for journal entry classification (Summary vs Detail, category hierarchy) |
| `dim_tour_product` | 40 | `seed_tour_plu` | PLU → DPR tour type mapping (mem_field_trip, mus_field_trip, revealed_tour, early_access_tour, etc.) |

## Changed (rebuilt from disabled placeholders)

| Model | Rows | Was | Now |
|-------|------|-----|-----|
| `dim_customer` | 1,037 | Placeholder (ID, STATUS); depended on missing `int_sf_crm` | Sources from `stg_gateway__tickets`; derives customer_type from CUSTNO prefix (Web, CityPass, Viator, Go City, GetYourGuide, Tiqets, Group, Pre-Sale, Rides/Partner) |
| `dim_gate` | 190 | Placeholder; depended on missing `int_ticket_scans` | Sources from `stg_gateway__acps` + `stg_gateway__facility`; combines ACP name, node, facility, capacity |
| `dim_product` | 1,168 | Placeholder; depended on missing `int_pos_retail` + `stg_shopify__products` | Sources from `stg_counterpoint__imitem`; includes pricing, category, barcode, price_tier derivation |
| `dim_ticket_type` | 7,336 | Placeholder; depended on missing `int_pos_tickets` + `ref_ticket_types` | Sources from `stg_gateway__items`; derives item_type (Ticket, Pass, Tour, Event, Merchandise) from pass_kind/event_type/stock_type |
| `dim_marketing_channel` | 7 | Had `enabled=false` despite no external dependency | Removed `enabled=false`; now builds from `ref_marketing_channels` seed |

## File moves

**Moved out of `models/marts/dimensions/disabled/` → `models/marts/dimensions/`:**
- `dim_customer.sql` (rewritten)
- `dim_gate.sql` (rewritten)
- `dim_product.sql` (rewritten)
- `dim_ticket_type.sql` (rewritten)
- `dim_marketing_channel.sql` (rewritten — removed `enabled=false`)

**Remaining in `disabled/`** (still awaiting external source connections):
- `dim_campaign.sql` — Salesforce
- `dim_fund.sql` — Blackbaud
- `dim_budget_version.sql` — Vena
- `dim_payment_method.sql` — no source data yet

## Updated

**models/marts/dimensions/schema.yml** — Full rebuild:
- Added column-level docs + tests for all 5 net-new + 5 rebuilt dimensions
- Primary key constraints + `unique` / `not_null` tests on all PK columns
- Descriptive column docs for key business columns (admission_type, item_type, customer_type, etc.)
- Retained entries for disabled dimensions (dim_campaign, dim_fund, dim_budget_version, dim_payment_method)

## Design Decisions

1. **Staging refs, not sources** — All dimension models `ref()` the `stg_*` staging views
   (which handle rename/recast/dedup) rather than going direct to `source()`. This keeps the
   dimension layer clean and leverages the existing staging contract.

2. **No identity resolution yet** — `dim_customer` derives type from CUSTNO prefix patterns
   rather than attempting cross-system matching (Gateway CUSTOMERID ↔ CounterPoint CUST_NO ↔
   Salesforce). That work is deferred until CRM feeds land.

3. **Access code classification** — The admission_type CASE statement in `dim_access_code`
   is based on observed ticket volume patterns and code ranges. Should be validated with
   someone who knows the Gateway configuration.

4. **Natural keys as PKs** — Surrogate keys (AUTOINCREMENT) used in the direct SQL creates
   on MARTS tables, but dbt models use the natural key as PK (item_id, event_id, etc.) since
   dbt doesn't manage sequences and natural keys are stable in this domain.

---
