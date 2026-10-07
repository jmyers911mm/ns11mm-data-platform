# 4.0.0: Model Optimization

- **Date:** 2026-07-21
- **Version:** 4.0.0

Session date: 2026-07-21. Started from "should we move CASE statements into dedicated
tables to join to?" and grew into a broader optimization pass. This doc is the
consolidated record of findings and delivered changes.

## Original question: CASE statements → join tables?

Mostly **no**. CASE-heavy models are heavy because they *pivot* (conditional aggregation
`SUM(CASE WHEN cohort THEN measure ELSE 0 END)`), which cannot become a join. Classify by job:

1. **Conditional aggregation / pivot** (bulk of `int_dpr__retail` 17×, `int_dpr__tour_revenue`
   16×) — keep inline; there is no table to join.
2. **Pattern-match derivation** (`matrix_code like '%TOU%'`, `line_type = 'S'`) — open set,
   keep inline.
3. **Enumerable code → label mapping** — the only kind that belongs in a seed/table. Already
   done well: `seed_tour_plu`, `seed_retail_item_facility`, `seed_retail_store_facility`.
4. **Repeated semantic flags** (`summary_category <> 6` = "is donation", 14× in one file) —
   the real DRY problem: centralize the magic numbers, not the CASE structure.

## Delivered changes (all verified output-equivalent unless noted)

1. **facility_group / is_donation refactor** — `int_counterpoint__retail_lines` now derives
   `facility_group` (name for the resolved key_facility) and `is_donation` once; `int_dpr__retail`
   consumes them, removing all 6 facility numbers + 14 donation literals. Patch:
   `dpr_retail_facility_group_refactor.patch`.

2. **int_dpr__fees_and_services PLU cohorts** — the two hardcoded PLU lists (each written twice)
   pulled into cohort CTEs, then promoted to a seed.

3. **seed_service_plu** — new seed (`plu, dpr_line_item, notes`) covering the audio-guide and
   product-178 mem+mus-tour PLUs; model wired to it via `ref()`; registered in `_seeds.yml`
   (+schema RAW). `int_dpr__tour_revenue` and `int_dpr__admissions` were reviewed and left
   unchanged — already seed-driven / open-set patterns, nothing to extract.

4. **fct_daily_operations — correctness fix.** Was silently inheriting `materialized=incremental`
   (merge on visit_date) while aggregating `sum(...) group by visit_date` over only newly-extracted
   rows → late/corrected rows OVERWROTE a day's totals with just the new slice (undercount).
   Converted to `table` (matches its day-grain siblings). Also wired `retail_revenue` /
   `retail_transactions` from `int_counterpoint__retail_lines` (non-donation top-line) and set
   `total_revenue = ticket + retail`, replacing hardcoded 0s. `retail_discounts` stays 0 —
   NO discount field in staged CounterPoint data (needs Gennady). 16-column output contract
   unchanged.

5. **dbt_project.yml materialization defaults.** Defaults were fiction: intermediate defaulted
   `incremental` but every model is a `view`; marts defaulted `incremental` but are `table`.
   That gap is what let #4 silently inherit incremental. Flipped defaults to reality —
   intermediate `view`, marts `table`, `reports` sub-group `view` — leaving incremental_strategy/
   on_schema_change as opt-in defaults (preserves `fct_ticket_availability`). Zero behavioral
   change to existing models; closes the inherit-incremental footgun for future ones.

6. **Hot intermediate views → table.** Multi-consumer views that re-ran their joins every
   consumer per build: `int_gateway__ticket_journal_lines` (7 joins ×3), `int_gateway__item_journal_lines`
   (4 ×2), `int_counterpoint__retail_lines` (3 ×3), `int_gateway__ticket_demand_features`
   (~120 lines ×2). Converted to `table` (build once, read N times). `int_ticket_scans` left a
   view (single-join thin passthrough — not worth materializing). Output identical; win is run time.

7. **Test coverage — two rounds.** Round 1: `int_counterpoint__retail_lines`, `int_pos_tickets`,
   `int_ticket_scans`, `int_ticket_inventory` + new fct_daily_operations columns. Round 2:
   `int_retail__{customers,performance,visitors}`, `int_gateway__ticket_demand_features`, 4 `rpt_`
   reports, 12 `stg_` models. Every previously-untested active model now covered. Severity rule:
   grain enforced by in-model GROUP BY → `error`; grain inherited or unverified source (incl. empty
   stubs) → `warn` (surfaces drift without breaking the daily build; promote after verifying).
   Files: `schema_test_additions.yml`, `schema_test_additions_2.yml`.

8. **fct_ticket_demand_forecast** — removed dead `hourly_demand` CTE (built but never selected);
   trimmed stale header NOTE. Output identical; one fewer aggregation per build.

## Investigated and deliberately NOT changed

- **`select *` in gold layer** — flagged early as drift risk; on inspection every gold model
  projects explicit columns in a `final`/`combined` CTE (`select * from final`, or
  `c.* exclude(...)` over an explicit CTE), so the `select *` live only in *import* CTEs and drift
  never reaches an output. Tightening would add verbosity for no drift benefit. No change made.
- `int_dpr__tour_revenue`, `int_dpr__admissions` — already well-factored (see #3).

## Open items (external / not code)

- `retail_discounts` in `fct_daily_operations` — no discount field in staged CounterPoint tables;
  confirm source with Gennady before publishing a discount metric.
- ADR-005 metric definitions for demand/attendance measures still owe the workshop.
- `warn`-severity tests: promote to `error` once the underlying source grains are confirmed.
