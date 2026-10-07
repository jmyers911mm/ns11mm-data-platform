# 7.13.1: Report Lineage Documentation (per-family pages + DPR rewrite)

- **Date:** 2026-08-11
- **Version:** 7.13.1

Documentation-only release. No model, seed, macro, test, or semantic-view change — `dbt
parse` output is byte-identical to 7.13.0. What changes is that the serving layer ADR-021
codified in 7.13.0 is now documented per report family, and that `DPR_LINEAGE.md`, last
revised in July at v1.5.0, describes the platform as it actually is.

## Added

- **`docs/architecture/lineage/` — one lineage page per report family**, matching the
  ADR-021 directory structure: `RETAIL_LINEAGE.md`, `TRACKER_LINEAGE.md`,
  `SCAN_LINEAGE.md`, `TODAY_SALES_LINEAGE.md`, `ATTENDANCE_LINEAGE.md`,
  `WEBSITE_COMMERCE_LINEAGE.md`. Each carries a mermaid graph of the full chain (staging →
  intermediate → fact → semantic view → serving models), a model inventory with ADR-021
  role and grain, the transformations that actually change numbers, and a caveats table.
  `restricted/` has no page by design — one PII extract, no semantic view.
- **`docs/architecture/lineage/LINEAGE_INDEX.md`** — family index, the seven-role reference
  table, the three cross-cutting rules (ratios never stored pre-divided, composites
  authored once, typed-NULL placeholders with a stated cause), the cross-family seams, and
  the open items that span every family.
- **`docs/architecture/ARCHITECTURE_FLOW.md` — "Per-report lineage" section** pointing at
  the index, so the platform-wide flow doc stops being the only place to look.

## Changed

- **`docs/architecture/DPR_LINEAGE.md` rewritten against v7.13.0.** The upstream half
  (source → staging → intermediate → `fct_daily_performance`) was substantially still
  correct and is kept. The downstream half is new: the DPR no longer ends at one `rpt_`
  model, so the doc now carries all thirteen models in the family with their ADR-021 roles,
  the period-window anchor logic and why MTD/YTD prior year is a calendar-year shift rather
  than −364 days, the composites-verified-to-the-cent record, the typed-NULL placeholder
  causes in `rpt_dpr_excel_export`, and the narrative chain including its sync guard.
- **`docs/README.md`** — adds the lineage index and `DPR_LINEAGE.md` to the architecture
  table, and ADR-020 / ADR-021 to the ADR log, which stopped at ADR-019.
- **`dbt_project.yml` version 7.13.0 → 7.13.1.** No other file in the dbt project changes.

## Fixed (stale documentation, not code)

Found while verifying every checkable claim against the repo:

- **`DPR_LINEAGE.md` said `fct_daily_performance` carries "~45 additive measures."** It
  carries **42**. Counted from the `combined` CTE.
- **`DPR_LINEAGE.md` described the Gateway comp-customer, placeholder-PLU, service-PLU and
  retail donation-item lists as literals in the models.** All four are now seed-driven
  (`seed_gateway_excluded_customer`, `seed_gateway_excluded_plu`, `seed_service_plu`,
  `seed_retail_donation_item`). The doc said "edit the model"; it now says "edit the seed."
- **The "`assert_critical_tables_not_empty` covers 6 of 17 tables, `fct_daily_scan` and
  `fct_today_sales_hourly` are gaps" line is stale** and was not carried into the new pages.
  The live test covers **15 tables and includes both**. Worth correcting anywhere else that
  line was copied from the older CHANGELOG entry.

## Findings recorded in the caveats tables (no code change this release)

Surfaced by the same verification pass. Each is documented where the affected family's
readers will meet it; none is fixed here.

- **`rpt_memorial_museum_tracker_ytd` carries a comment claiming `cafe1_donations` is "not
  surfaced in `fct_daily_performance` yet."** It has been for some time. Either add it to
  that model's donation total or drop the comment — leaving both is how a stale note becomes
  a believed fact.
- **`T_TODAY_SALES_NARRATIVE` fires once at 05:30 ET** against an intraday day-to-date
  brief, so it narrates the pre-opening state. The setup script documents the blocker
  (hourly firing needs the append-only `NOT IN` dedupe replaced with delete-and-insert for
  the current date). The most consequential open item in that family.
- **No `today_sales` model carries the `intraday` tag**, so none picks up the 300-second
  statement timeout in `dbt_project.yml`; the tag exists only on `fct_ticket_availability`.
  Intent and configuration have drifted.
- **`rpt_attendance` pulls Sensource's own `mem_attendance` / `mus_attendance` into a CTE
  and never selects them.** Dead columns.
- **The Website Commerce `revenue_type` split is an ungoverned string heuristic**
  (`like '%member%'` / `'%don%'` over `order_type` or `title`), copied verbatim into three
  models. A new order type matching neither falls to `'Other'` and silently changes the
  totals. A seeded mapping under the ADR-005 gate is the obvious remedy.
- **The Website Commerce family carries zero ADR-021 role suffixes** across its three
  models — the only family entirely outside the grammar.
- **`models/exposures.yml` is stale across every family**, still pointing at facts and
  legacy models rather than at the serving stacks built in 7.10.0–7.13.0. RPT-013's
  description still reads "STUB: Classy / Shopify recurring feed pending ADR-008" though the
  Drupal recurring feed is live.

## Verified

- Every model name, `ref()` edge, seed row count, `availability = 'Stub'` count,
  semantic-view metric count, facility ID, item number, threshold, cron expression and
  composite total in the eight documents was checked against the repo. Nine errors were
  found in draft and corrected before publication: three family model counts, the
  `rpt_tracker_powerbi` composite component count (20, not 19), the `fct_daily_scan` budget
  unpivot branch count (13, not 12), the `fct_daily_performance` measure count, the stale
  test-coverage claim above, and a reference to `snowflake/01_apply.sql`, which ships in the
  release payload rather than in this repo.
- All mermaid graphs parse; every node used in an edge is declared. All relative links
  resolve.
- Claims not checkable from static code — the July extract conservation figures, the dev
  PBIX attendance discrepancy, the empty SDLY column in dev — are labelled as observations
  rather than asserted as current state.

## Open items carried forward

- ADR-021 §3 still needs Data & AI Committee ratification. The lineage pages cite it as
  Proposed throughout.
- `TOTAL_ESTIMATED_REVENUE` is still authored twice (`rpt_dpr_mtd_ytd_long` and inline in
  `rpt_dpr_report_long`). Carried from 7.13.0; now also documented in `DPR_LINEAGE.md` so it
  is visible to readers rather than only to the ADR.
- The DPR and Retail period-window definitions are still unvalidated against the legacy
  `.prpt` files.
