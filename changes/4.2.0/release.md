# 4.2.0: Conformed dim_facility & Config-as-Data Cleanup

- **Date:** 2026-07-23
- **Version:** 4.2.0

*Errata (2026-07-29): this entry discusses `dim_marketing_channel` as a kept passthrough dim; the model was subsequently removed from the repo without a changelog entry. See the Reconciliation subsection of [6.2.0].*

Session date: 2026-07-23. Started from "where should we join the new `dim_*` tables in to make
filters cleaner?" The review found `dim_date` was already wired into 13 models and the other
ten dims were built ahead of their consumers, so the question turned into a codebase-wide audit
for `facility_group`-style issues — inline enumerable code→label maps, repeated magic-number
literals, and duplicated join/CTE blocks. That produced three batches of **output-equivalent**
cleanups (verified; see below). No breaking changes: every touched model keeps its column
contract.

## Added (net-new models)

| Model | Grain | Source | Purpose |
|-------|-------|--------|---------|
| `dim_facility` | key_facility | `seed_facility_area` | Conformed facility/area dimension. Single home for `key_facility → area_name / area_group / is_selling / facility_group`, previously re-selected inline in three retail facts + `dim_store` and derived as an inline CASE in `int_counterpoint__retail_lines`. |
| `int_gateway__item_attributes` | avg_id | `stg_gateway__vattribute` | Shared `avg_id → matrix_code / recognize_basis / default_customer / dynamic_channel` lookup, previously re-selected in three gateway intermediates. Raw passthrough — consumers keep their own coalesce/`visit_type` derivations. |

## Added (net-new seeds — config-as-data)

| Seed | Rows | Replaces inline literal in |
|------|------|----------------------------|
| `seed_retail_store_scope` | 9 | `int_counterpoint__retail_lines` store-scope `IN` list |
| `seed_retail_zero_price_item` | 2 | `int_counterpoint__retail_lines` zero-rated-SKU list |
| `seed_retail_excluded_item` | 1 | `int_counterpoint__retail_lines` hygiene exclusion |
| `seed_retail_donation_item` | 4 | `int_dpr__retail` donation-SKU `item_no` literals (→ `donation_line`) |
| `seed_gateway_excluded_plu` | 1 | `int_gateway__ticket_journal_lines` placeholder-PLU exclusion |
| `seed_gateway_excluded_customer` | 2 | `int_gateway__ticket_journal_lines` `itm_default_customer_id` exclusion |

## Changed (models rewired — output-equivalent)

| Model | Change |
|-------|--------|
| `int_counterpoint__retail_lines` | `facility_group` CASE → `seed_facility_area` lookup (`coalesce(…, 'other')`); store scope / zero-price / excluded-item literals → seeds. |
| `fct_retail_daily`, `fct_retail_performance` | Dropped inline `seed_facility_area` `area` CTE; now `left join dim_facility`. |
| `fct_today_sales_hourly` | Third consumer of the area seed; area label now from `dim_facility`. |
| `dim_store` | `store_type` (=`area_group`) now sourced from `dim_facility` instead of re-reading `seed_facility_area`. |
| `int_retail__performance` | Raw `summary_category = 6` (×5) → the `is_donation` flag already exported by `int_counterpoint__retail_lines` (completes the 4.0.0 refactor, which had missed this model). |
| `rpt_retail_carts_analysis` | Raw `key_facility = 1020 / 1030` → conformed `area_name` (`'Memorial Carts'` / `'Atrium'`). |
| `int_retail__visitors` | Hardcoded `1234 as key_facility` → `{% set ecom_key_facility = 1234 %}` var. |
| `int_gateway__ticket_journal_lines` | `vattribute` CTE → `int_gateway__item_attributes`; PLU/customer exclusions → seeds (`NOT EXISTS` preserves the NULL-customer-kept behavior). |
| `int_gateway__item_journal_lines`, `int_gateway__scan_lines` | `vattribute` CTE → `int_gateway__item_attributes`. |
| `int_dpr__retail` | Donation-SKU `item_no` literals → `seed_retail_donation_item.donation_line` (mirrors the 4.0.0 `seed_service_plu` pattern). |

## Updated (seeds & schema)

- **`seeds/seed_facility_area.csv`** — added `facility_group` column (`museum_store`, `memorial_carts`, `museum_cafe`, `mag_cart`, `mus_ag`, `ecommerce`; `1030`/`1070`/`1080` → `other`, matching the old CASE else-branch).
- **`seeds/_seeds.yml`** — registered the 6 new seeds (with `column_types` pins so alphanumeric `item_no`/`plu` are not coerced to numeric) and documented the new `facility_group` column with `not_null`.
- **`models/marts/dimensions/schema.yml`** — added `dim_facility` (PK `facility_key`; `not_null` on `area_name` / `area_group` / `facility_group`).

## Verification

- **Ref graph** — every `ref()` in the 15 touched/new models resolves against the model + seed set (incl. the 6 new seeds); no rewritten model left a dangling CTE alias.
- **Truth-table equivalence proofs** — the three non-mechanical transforms were checked exhaustively: the `facility_group` CASE vs. seed-join+`'other'` across all keys; the customer exclusion (`NOT IN (…) OR IS NULL` vs. `NOT EXISTS`, including the NULL-kept case); and `summary_category (<>6 / =6)` vs. `(not is_donation / is_donation)`.

## Design Decisions

1. **`dim_facility` is a new dim, not `dim_store`.** The duplicated area join is at `key_facility`
   grain; `dim_store` (built in 4.1.0) is `store_id` grain, so it could not deduplicate it. The
   retail facts join the new `key_facility`-grained `dim_facility`.

2. **`facility_group` lives in the seed, joined in silver — not pulled from the mart dim.**
   `int_counterpoint__retail_lines` is an upstream intermediate; having it `ref()` a mart dim
   would reverse layering. Instead the mapping went into `seed_facility_area` (reference data's
   natural home) and both `dim_facility` and the intermediate read the seed. Dims are otherwise
   joined only in the marts layer.

3. **`1030` / `1070` / `1080` stay `facility_group = 'other'`** (product decision), so
   `rpt_retail_carts_analysis` references facilities by unique `area_name` rather than group.

4. **Gateway attribute model is a raw passthrough.** It exposes `stg_gateway__vattribute`
   columns unchanged (no coalesce), so each consumer's existing `matrix_code` handling and the
   `gateway_recognized_date` / `gateway_general_admission_flag` macros work with zero column
   changes. Standardizing scan-line's NULL→'' handling was deliberately *not* done (would alter
   output).

## Investigated and deliberately NOT changed

- **`dim_date`** — already joined in 13 models; nothing to do beyond an optional inline cleanup
  in `int_gateway__ticket_demand_features` (skipped to keep intermediate free of mart refs).
- **Passthrough dims** — `dim_tour_product` (= `seed_tour_plu`) and `dim_marketing_channel`
  (= `ref_marketing_channels`): rewiring consumers to ref the dim inverts layering for zero
  dedup; kept the seed refs.
- **`store_facility` CTE** (`seed_retail_store_facility`, in retail_lines + today_sales_hourly) —
  left inline; centralizing via `dim_store`'s `min(key_facility)` aggregation risked changing
  fan-out.
- **`demand_level` bands, "sold tickets" base CTE, `%MEMORIAL%`/`%member%` name-match ladders** —
  single-use or open-set; consistent with the 4.0.0 keep-inline rules.

## Open items

- **`int_dpr__retail` (Batch C) is the highest-risk change** — it moves delicate donation
  double-count logic onto a seed join. Logic is preserved, but run a before/after row-count and
  per-column sum diff on this model specifically before merge.
- Several Batch C seeds are single-row (`seed_retail_excluded_item`, `seed_gateway_excluded_plu`);
  fold back inline if the extra seed files aren't worth the ops-editability.
- Suggested build gate: `dbt build --select int_counterpoint__retail_lines+ int_gateway__item_attributes+ dim_facility+`.

---
