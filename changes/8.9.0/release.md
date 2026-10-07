# 8.9.0: Donations Analysis Report

- **Date:** 2026-08-12
- **Version:** 8.9.0

Builds the sixteenth of the seventeen live reports and, with it, the two legacy tables the
Donations chain writes: `fact_all_donations` and `fact_donations_analysis_report`. Both are
load-bearing beyond their own report surface — five other migrated live reports read them.
Not gated: no certified metric definition changes, and no measure is added to
`fct_daily_performance`. **No existing number moves** — every model this release reads is
read-only here.

## Added

- **`int_donations__all_sources`** — the `fact_all_donations` equivalent at component grain,
  carrying fifteen atomic components. Eleven are **re-projected** from models that already
  author them (a donation total authored twice is an ADR-021 defect even when the two copies
  agree today); three are new and each is defined as the *complement* of something already
  authored, so no dollar is authored twice and the legacy whole recomposes by addition
  (`MEMORIAL_KIOSK_DON`, `MEM_CART_OTHER_DON`, `VESEY_DON`); one is a typed NULL.
- **`fct_donations`** — the `fact_donations_analysis_report` equivalent, day grain. It uses
  **legacy column names deliberately**: the table is a binding contract for five `.prpt`
  reports, not just an input to a sixth.
- **`rpt_donations_report_long`** (serving shape; it carries the `POWERBI_ROLE` grant and is
  the Power BI surface for this family), **`rpt_donations_narrative_brief`**,
  **`rpt_donations_narrative`** (`enabled=false`), **`dim_donations_line_item`**,
  **`donations_line_items` seed** (36 lines, 12 sections).
- **No `rpt_donations_powerbi`, and the reason is structural.** There is no `DONATIONS`
  semantic view — `_reports__sources.yml` declares exactly three — and authoring a fourth
  means authoring a new certified metric surface, which is an ADR-005 decision that does not
  belong in an ungated release. A wrapper with no semantic view behind it would be a copy of
  `fct_donations` wearing a reserved suffix.
- **Three tests**: `assert_donations_tie_to_daily_performance` (error — the eleven shared
  lines must agree), `assert_gateway_donation_cohorts_recompose` (error — the complement
  split must partition the cohort), `assert_cart_donation_composition` (warn).
- **`dbt_project.yml` version 8.8.0 → 8.9.0.**

## Findings recorded in the caveats tables (no code change this release)

- **Legacy double-counts the box-office exit box across two of its seven legs.**
  `t_run_donations_kiosk_coatcheck` writes the whole of `fact_all_gateway_donations`, which
  includes `DONOPSMUS003`; `t_run_donations_exit` then writes `fact_retail` item 886 UNION
  `box_office_mus_exit_don` — the same PLU's dollars again. Any consumer adding
  `kiosk_coatcheck_donations + mus_exit_donations` counts the museum exit box twice, and
  `finance_mtd_dpr` and `finance_ytd_dpr` read both legs. **Reproduced verbatim** so those two
  reports tie on migration, flagged in the model header, the `schema.yml` and the section-12
  note, and deliberately **not** silently fixed. *Owner: Chris Wogas / Finance.*
- **`911dw.dim_item_descr` is not staged and its surrogate keys cannot be recovered.** Six
  legacy legs filter on integer keys inside an already donation-flagged category. Four SKUs
  are resolved and seeded; the rest are approximated by the category filter at the same
  facility, which makes `MUS_STORE_DON`, `VESEY_DONATIONS`, `MEM_CART_ASK_DON`,
  `RETAIL_CART_DON` and their two dependent ratios **supersets** of the legacy cohorts. All
  six are `Partial`.
- **`911dw.cafe_performance` has no writer** anywhere in the 216 migrated transformations and
  no staged equivalent, so `CAFE_VENDOR_DON` is a typed NULL (cause: *no data feed*) and
  `CAFE_DONATIONS` / `LEG_CAFE` are `Stub`. Not zero-filled. The vendor-cafe era ended
  2023-01-01, so this is a historical hole rather than an ongoing one — and the legacy Excel
  tab already prints `cafe1_donations AS cafe_donations`, i.e. the report abandoned the vendor
  feed for the CounterPoint cafe and never renamed the column.
- **No cross-source donations total is authored, deliberately.** Legacy publishes two
  incompatible roll-ups that disagree structurally, not just numerically: `fact_all_donations`'
  seven legs (which double-count the exit box and exclude `cafe1_donations`,
  `vesey_donations` and `mask_donations` entirely), and `t_reporting_donations`' DPR
  `donations` line (whose issued leg does not carve out categories 3220/3221 and which then
  adds the kiosk/coatcheck leg on top). Picking one changes what a certified metric counts.
  Every component is published; both compositions are reconstructable; the narrative prompt is
  explicitly instructed never to state or imply a cross-source total. *ADR-005, owner: Chris
  Wogas.*
- **The legacy `coatcheck_don` and the platform's are not the same cohort.** A side-by-side
  against the legacy XLSX will show the coat check line low by exactly the exit-box amount
  from 2024-02-15 onward; section 9 makes up the difference and the shipped test asserts the
  identity.
- **`mem_attendance` is `Available` here and `Stub` on the DPR — same word, two measures.**
  The Donations report's legacy source is the Sensource sensor at 2000, which is live; the
  DPR's is the scan chain, which is a typed NULL because no Gateway ACP resolves to
  `key_facility` 2000. Both seeds are correct for their own report; it reads as an
  inconsistency in a seed diff, so it is called out.
- **The legacy workbook is thirteen per-year sheets, not twelve.** `t_donations_analysis_tabs`
  carries thirteen writer steps — 2014 through 2026 — each writing the same 22-column layout
  filtered by a `SwitchCase` on `year(key_date)`, and it grows by one every January. There is
  no sheet-level sectioning in the legacy file at all; the twelve sections in the layout seed
  are the platform's grouping.
- **`mus_store_donations` in `int_dpr__retail` is broader than every legacy consumer of it**,
  and the two legacy consumers do not even agree with each other. Pre-existing platform
  behaviour, already published on the DPR; recorded here because this is the first surface
  where the difference is visible line by line.
