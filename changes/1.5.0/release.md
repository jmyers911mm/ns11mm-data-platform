# 1.5.0: DPR Metric Reconciliation: Legacy Parity Fixes

- **Date:** 2026-07-08
- **Version:** 1.5.0

Full logic/lineage audit of all ~40 DPR base metrics against the legacy Pentaho
definitions (`report_details_pt` / `transforms_pt`), followed by a fix sprint.
Nine fixes shipped and validated against Snowflake; every remaining gap is
documented as an extract-scope or definitional item (see Known Issues).
Companion artifact: `dpr_metric_reconciliation_audit_v3.xlsx`.
 
## Critical Bug Fixes
 
- **`gateway_recognized_date` macro** — recognize-basis 182 (92% of ticket volume)
  keyed on `rme.start_at`, which is null for 111K rows; combined with
  `jnltickets.ticketdate` being ~95% unparseable, ~116K of 128K ticket units got a
  null `key_date` and were silently dropped. All branches now coalesce to
  `end_of_life_date` (the visit date, same substitution as the 1.4.0
  `stg_gateway__tickets` fix): basis 182 → `coalesce(start_at, end_of_life_date,
  ticket_date)`; 185/else → `coalesce(ticket_date, end_of_life_date)`. Enriched
  journal recovered 8,267 → 105,781 qty; GA + tour partition reconciles to the
  penny (96,326 / $2.68M GA + 9,455 / $262K tours = $2,942,119.89)
- **Systemic PLU trim** — Galaxy stores `plu` as space-padded `CHAR(20)`, which
  silently defeated every downstream equality join and filter. `trim(plu)` now
  applied at source in `stg_gateway__items`, `stg_gateway__jnltickets`, and
  `stg_gateway__jnlitems` (all three together to keep bridge joins aligned).
  Un-zeroed: `box_office_mem_don` ($28,362), `box_office_mus_exit_don` ($8,160),
  and the Galaxy component of `audio_tour_headset`
- **Cafe wired in** — `cafe1_all_profit` / `cafe1_donations` were structurally
  zero: CounterPoint store 1 was outside the retail store scope and facility 4007
  was never mapped. Added store 1 → 4007 to `seed_retail_store_facility` and
  widened the scope in `int_counterpoint__retail_lines`. Validated: profit
  $68,434 / donations $7,219 (COGS coverage confirmed at 99.8% of cafe lines)
- **`mem_mus_tour_revenue` / `mem_mus_tours`** — legacy keys on `rItmProductID =
  178`, whose PLUs carry no matrix code, so the `%MTG%` matrix filter matched
  nothing. Switched to the product-178 PLU list (`MUSMMUADW001/003/005`) in
  `int_dpr__fees_and_services`. Validated: 1,262 tours / $107,270 (was 0)
## Donation Re-sourcing & Corrections
 
- **`mask_donations` / `donation_box`** — re-pointed from the Gateway item
  journal (wrong system) to CounterPoint retail per legacy spec: items `200704`
  (mask, dormant since 2021) and `101165` (Plaza Donation Box, $1,809 validated).
  Measures moved to `int_dpr__retail`; `fct_daily_performance` re-wired
- **Legacy surrogate keys resolved by inspection** — `dim_item_descr` surrogates
  were being used as CounterPoint `item_no`: 483 → `'7-999'` (Donation Ask),
  886 → `'101375'` (Donation Box Store Exit; `item_no` is alphanumeric, so the
  numeric surrogates could never match). `mus_exit_donations` now $1,816 (was 0);
  `cart_donation_ask` narrowed to the ask item at the carts ($11,023), removing a
  double-count with the plaza box; `mus_store_donations` excludes the exit-box
  item ($25,993)
- **`coatcheck_don`** — now excludes PLU `DONOPSMUS003`: its matrix also matches
  `%DON-OPS-MUS%`, so once the PLU trim landed the exit-box dollars would have
  counted twice (pre-trim they landed only here). Ships with the trim by design
- **`ticketing_donations`** — member-desk PLU `DONMBRMUS001` excluded per legacy
  spec (booked to Membership); dormant in the current window, guards history
- **`mem_audio_guide_revenue`** — added the CounterPoint facility-1040 component
  (`mag_cp_revenue` in `int_dpr__retail`), the primary MAG source since 2023.
  The item-override seed carved those lines out of the carts but no measure
  aggregated them. Combined with the Galaxy `%MAG%` component in the fact.
  Dormant in the current extract window; wiring validated
## Seeds
 
- **`seed_tour_plu`** — full rebuild from the legacy `product_logic` PLU lists
  (40 PLUs, 8 categories). Corrects: `revealed_tour` = `VTMUSOBLOADW001` (was
  mislabeled early-access PLUs), `mem_field_trip` = `VTEDUMEM*` (was youth &
  family), `mus_field_trip` = `VTEDUMUS*` (was early-access). New exclusion
  categories `youth_fam_tour`, `early_access_tour`, `ea_mem_mus_tour` fix the
  `mus_guided_tours` over-count ($84,062 post-fix)
- **`seed_retail_store_facility`** — store 1 → facility 4007 (Museum Cafe;
  store id to be confirmed with Retail)
- **`_seeds.yml`** — `accepted_values` and descriptions updated for both
## New Models & Semantic Layer
 
- **`int_dpr__attendance`** — memorial attendance (`mem_attendance`) plus scanned
  museum attendance from `int_ticket_scans` + facility classification
- **`int_dpr__tour_revenue`** — added `mem_guided_tours` /
  `mem_guided_tour_revenue` (`%MGT%` cohort)
- **`fct_daily_performance` / `rpt_daily_performance_report`** — new measures
  surfaced; donation columns re-wired to their corrected sources
- **`semantic_models/dpr.yaml`** — fully synced with the fact: 49 metrics (every
  additive measure individually queryable, composites retained), complete
  `dim_date` dimension set including the fiscal calendar (FY starts October),
  fixed an incorrect "fiscal year" synonym on `calendar_year`, new verified
  queries and fiscal-aware SQL-generation instructions
## Diagnostics Verified Healthy (no change needed)
 
- `jnlheaders.tran_date` parses 100% (206,052/206,052) — item-journal `key_date`
  is sound
- Journal codes 532/610 identified as tender/deposits (Visa/MC/Amex/Cash/Wire,
  $4.7M payment mirror) — correctly ignored by the models
## Known Issues / Blocked on Extract
 
- `disbursement_id` (all rows) and `order_line_id` (codes 33/35/37/52) arrive as
  literal 0 — export artifact; blocks the tour-with-GA cohort and code
  identification
- COA extract missing the accounts behind journal codes 33/35/37/52 (~$7.8M);
  code 33 is likely the standalone service-fee postings — `service_fees` reads 0
  until resolved
- Extract windows are recent-only (CP: 2026-06-01..07-06); retired/seasonal
  products (virtual tours, Revealed, masks) require the history load. CP stores
  8/10 absent
- `RMEvents.start_at` null for 111K basis-182 rows (fallback in place; true event
  dates needed for tour products)
- Unissued population confirmed present in `orderlines` (5,703 units / $1.9M
  order book) — buildable pending the ADR-005 definition decision
- `create_dpr_semantic_view.sql` (native DDL twin) not yet regenerated to match
  the rebuilt `dpr.yaml`
