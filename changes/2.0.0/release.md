# 2.0.0: Semantic & Governance Layer: Metric Metadata, Report Exposures, Charter

- **Date:** 2026-07-16
- **Version:** 2.0.0

With the report-estate marts now fed with real data (1.6.x), this release
formalizes the **semantic and governance layer** on top of them. Every
certified metric carries a full governance metadata block and a report
cross-reference; the report estate is registered as dbt exposures mapped to
those metrics by ID; and two governance documents land under `docs/`. Major
version: the metric-identifier scheme (`MET-###`), the report-identifier scheme
(`RPT-###`), and the metric/exposure `meta:` contracts are now stable and
consumed downstream by the Hub registries and Cortex Analyst.

## Added — metric governance metadata (`semantic_models/`)

Full 17-field `meta:` block on **every metric** across `dpr.yaml`,
`attendance.yaml`, `fundraising_ecom.yaml`, and `retail.yaml` — **72 certified
metrics**, `MET-001`..`MET-072`. Fields: `display_name`, `id`, `type`,
`domain`, `status`, `grain`, `sla_tier`, `version`, `business_owner`,
`technical_owner`, `approval_date`, `time_dimension`, `scope`, `source_models`,
`related_metrics`, `caveats`, `changelog`.

- **`attendance.yaml`** — `MET-050`..`MET-056` (7 metrics), domain
  *Attendance & Ticketing*, owner Chris Wogas. Hourly-grain metrics flagged;
  scan/attendance stubs (Sensource blend, real-time CounterPoint) noted in
  `caveats`.
- **`fundraising_ecom.yaml`** — `MET-057` (1 metric), domain *Fundraising*,
  owner Jan-Michael Llanes.
- **`retail.yaml`** — `MET-058`..`MET-072` (15 metrics), domain *Retail*,
  owner Gennady Zaritsky. Ratio metrics (`profit_margin`, `avg_sale`,
  `conversion_rate`, `rev_per_visitor`) typed `Measure — Ratio` and flagged
  non-additive.
- `dpr.yaml` — `MET-001`..`MET-049`, aligned to the same contract.
- All metrics `status: in-review` with blank `approval_date`, pending domain-
  owner certification (ADR-005). `time_dimension: report_date`,
  `technical_owner: Jeremy Myers`, initial `changelog` entry on each.

## Added — report ↔ metric cross-reference (`semantic_models/`)

- New `reports:` field on every metric's `meta:`, listing the reports that
  consume the metric (the inverse of `exposures.yml`'s `metrics` list). **22
  metrics reference at least one report.**

## Added — report estate as dbt exposures (`models/exposures.yml`)

Rewrote `exposures.yml` (previously a single sample) with **13 Pentaho
migration reports** documented as dbt exposures:

- **DPR family** — Daily Performance Report, YTD, MTD, Excel Data, Memorial &
  Museum Daily Tracker.
- **Retail** — Today's Sales (Hourly), Retail Performance, Retail Carts
  Analysis, Monthly Retail KPI.
- **Attendance / scanning** — Daily Scan, Attendance, Daily Attendance.
- **Fundraising** — Website Commerce Report.

Each exposure carries native dbt fields plus a `meta:` block: `id`
(`RPT-001`..`RPT-013`), `domain`, `report_type`, `platform: Power BI`,
`legacy_platform: Pentaho`, `disposition` (`MIGRATE` / `CONSOLIDATE`),
`status`, `target_model`, `source_models`, `metrics` (referenced by `MET-###`),
`packages`, `caveats`, `version`, `changelog`.

- **`depends_on` pinned to each report's live base fact** (e.g.
  `fct_daily_performance`, `fct_retail_daily`, `fct_today_sales_hourly`,
  `rpt_website_commerce`) so `dbt parse` succeeds; the full migration target is
  recorded in `meta.target_model`. Each `ref()` must resolve to an ENABLED
  model or parse will fail.

## Added — governance documents (`docs/`)

- **`docs/policy/AI-CHARTER.md`** — AI & Data Governance Charter (v0.1):
  purpose, scope, and the seven governing principles, with sections IV–VII
  (governance structure, data/AI frameworks, compliance) marked for committee
  development. The "why" to the AI policy's "how."
- **`docs/governance/adc_meeting_records.md`** — AI & Data Committee meeting
  records in a structured, machine-readable markdown format (one `##` section
  per meeting; `Agenda` / `Decisions` / `Action Items` subsections with
  inline `owner` / `due` / `status`). First record: the AI-policy refresh and
  draft-charter meeting.

## Notes

- The metric metadata and exposures are consumed **live** by the Hub Metric
  Registry and Report Registry (bidirectionally cross-linked by `MET-###` and
  `RPT-###`) and by Cortex Analyst.
- `meta:` is valid dbt but is **not** part of the Cortex Analyst spec — strip
  before Cortex upload if a validator rejects unknown keys.
- Everything new is `in-review`. Owner sign-off and `approval_date` are the
  next gate (ADR-005) before any metric or report is promoted to certified.
