# 1.6.0: Active Pentaho Report Estate + Domain Semantic Layer

- **Date:** 2026-07-15
- **Version:** 1.6.0

Built out the remaining active Pentaho analytical reports on top of the DPR
marts, established the reusable report-model pattern (intermediate → fact →
report → semantic), and expanded the semantic layer from one DPR model to four
domain-grouped models so every report is queryable through Cortex Analyst. The
~90 SSRS reports are Galaxy operational/box-office admin reports and remain out
of scope. Companion docs: `docs/architecture/REPORT_TABLE_COLUMN_CROSSWALK.md`,
`docs/architecture/DPR_LINEAGE.md`.
 
All 14 active Pentaho reports are now scaffolded: 4 DPR (existing) + 5 live on
current seeds + 5 wired to stub seeds pending a source feed.
 
## Added
 
### Report-estate facts (`models/marts/facts/`)
 
- **`fct_retail_performance`** — tidy category-grain retail fact (one row per
  day × facility × product category); additive sales/profit/units/donations.
  Replaces legacy `fact_retail`.
- **`fct_retail_daily`** — facility-grain retail fact: transaction counts,
  visitor counts, and facility rollups; the grain the retail ratios operate on.
  Replaces legacy `fact_num_tickets` plus the facility rollup of `fact_retail`.
- **`fct_daily_scan`** — gate passes scanned + tickets sold by market segment
  per day. Replaces legacy `fact_dailyscan_data`.
- **`fct_today_sales_hourly`** — same-day hourly retail sales by facility
  (STUB: real-time CounterPoint feed pending).
### Report models (`models/marts/reports/`)
 
- **`rpt_retail_performance`** — Retail Performance Report: ratios
  (conversion, rev-per-visitor, avg sale, margin, per-cap donations) as
  ratio-of-sums at query grain, plus category drill-down. Template for the estate.
- **`rpt_retail_carts_analysis`** — Retail Carts Analysis: memorial-carts lens
  with the legacy adjusted-visitor denominator (mem visitors − 25% − mus visitors)
  for capture rate and per-cap.
- **`rpt_monthly_retail_kpi`** — Monthly Retail KPI: `fct_retail_daily` rolled to
  fiscal month × area, ratios recomputed at the month grain.
- **`rpt_memorial_museum_tracker_ytd`** — Memorial Museum Daily Tracker YTD:
  fiscal-YTD variance tracker over `fct_daily_performance` (windowed cumulative
  partitioned by fiscal year).
- **`rpt_daily_scan`** — Daily Scan Report: market-mix shares and scan
  utilization at query grain.
- **`rpt_attendance`** — Attendance Report (STUB: Sensource area counts).
- **`rpt_daily_attendance`** — Daily Attendance Report (STUB: hourly passes;
  scan-based fallback).
- **`rpt_website_commerce`** — Website Commerce Report (STUB: Classy/Shopify
  recurring, ADR-008).
- **`rpt_wifi_email_export`** — Blue State WiFi email export.
  **RESTRICTED / PII**: tagged `pii`/`restricted`/`marketing_export` so the
  `on-run-end` masking hook applies; PII columns marked
  `classification: restricted_pii` / `contains_pii: true`. Least-privilege grant
  only (marketing-export role); must NOT be granted to `POWERBI_ROLE` / `ML_ROLE`.
  See `docs/architecture/DATA_CLASSIFICATION.md`.
### Intermediate models (`models/intermediate/`)
 
- **`int_retail__performance`** — day × facility × category retail aggregation.
- **`int_retail__customers`** — facility-grain transaction counts
  (`count(distinct doc_id)`; non-additive across category, kept separate).
- **`int_retail__visitors`** — Sensource visitor + Shopify ecom counts (STUB).
- **`int_gateway__scan_lines`** — scan events joined to their ticket's market
  segment via `usage.visual_id = jnltickets.visual_id`, then matrix/channel.
### Seeds
 
- **`seed_facility_area`** (reference) — selling-area labels for facility keys
  (1003 Museum Store, 1020 Memorial Carts, 1030 Atrium, 1234 Ecommerce, 4007
  Cafe, 1040/1060 audio, 1070 tour guides, 1080 memberships).
- **`seed_scan_market_segment`** (reference) — market-segment map for the Daily
  Scan Report (CityPASS, C3, Explorer, GoCity, School Groups, Members, Walk-up, …).
- **Stub seeds** (`seeds/_tmp/`, schema `raw_seed`, tags `build_temp`/`stub`):
  `tmp_seed_sensource__visitors`, `tmp_seed_sensource__attendance`,
  `tmp_seed_shopify__orders`, `tmp_seed_ecom__recurring`,
  `tmp_seed_gateway__passes_by_hour`, `tmp_seed_cp__today_sales`,
  `tmp_seed_retail__budget`, `tmp_seed_dsr__budget`, `tmp_seed_wifi__audience`
  (the last tagged `pii`/`restricted`).
### Semantic layer (`semantic_models/`)
 
- **`retail.yaml`** → `MARTS.RETAIL` — spans `fct_retail_daily` (facility grain,
  ratios) and `fct_retail_performance` (category grain) so both facility-level
  and product-category questions are answerable. 15 metrics.
- **`attendance.yaml`** → `MARTS.ATTENDANCE` — spans `fct_daily_scan`,
  attendance measures, and `fct_today_sales_hourly`. Covers Daily Scan,
  Attendance, Daily Attendance, Today's Sales.
- **`fundraising_ecom.yaml`** → `MARTS.FUNDRAISING_ECOM` — Website Commerce
  recurring revenue (STUB-fed).
- Stub-fed surfaces carry `module_custom_instructions` guardrails: the agent
  reports an empty result as "feed not yet connected", never "revenue was zero".
  `museum_attendance` is flagged as a GA-ticket proxy; Daily Scan segment splits
  are flagged provisional (totals reliable) pending channel-mapping validation.
### Documentation
 
- **`docs/architecture/DPR_LINEAGE.md`** — table-relationship and
  transformation reference for the DPR slice, with a Mermaid `graph LR` lineage
  diagram and per-layer transformation notes.
- **`docs/architecture/REPORT_TABLE_COLUMN_CROSSWALK.md`** — report → model →
  base-table matrix, the old→new column crosswalk per base table, and per-report
  measure mapping (legacy field → new mart column).
- READMEs updated: root, `semantic_models/`, `models/marts/facts/`,
  `models/marts/reports/`.
## Changed
 
- **`int_ticket_scans`** — exposes `visual_id` (passthrough) to enable the scan →
  ticket market-segment join for Daily Scan. Grain and existing consumers
  unchanged.
- **Semantic layer scope** — expanded from a single DPR model to four
  domain-grouped models (DPR / retail / attendance / fundraising_ecom). Design:
  one model per business domain (not per fact), each spanning its facts, so
  cross-report questions within a domain work; facts are never join-fanned in a
  single query.
## Known Issues / Follow-ups
 
- **Daily Scan segment mapping is provisional.** `seed_scan_market_segment` maps
  against `acs_dynamic_channel` (sales channel) as the closest structured proxy;
  the legacy `t_fact_dailyscan_data` transform was undocumented in the source.
  Passes/sold totals are correct; the per-segment split needs validation
  (`select category, count(*), sum(scanned_qty) from int_gateway__scan_lines
  group by 1`). If channels are generic, pivot the seed to `sales_program_id`.
- **`cafe1_donations` not surfaced in `fct_daily_performance`.** It exists in
  `int_dpr__retail` but was never added to the fact, so it is omitted from the
  Memorial Museum Tracker YTD donation sum. Surface it to the fact to close the gap.
- **Stub-fed reports await source feeds** (each a seed/staging swap, no report
  rework): `sensordata` (Sensource — Attendance ×2, retail conversion ratios,
  true DPR `mus_attendance`), hourly passes, real-time CP (Today's Sales),
  Classy/Shopify recurring (Website Commerce), WiFi audience, budget/forecast.
  Add a thin `stg_<source>__<entity>` between each new RAW table and the marts
  when it lands.
- **WiFi export access grant** is a governance-tier decision: confirm the
  marketing-export role grant and that `POWERBI_ROLE`/`ML_ROLE` are excluded.
- **Native semantic-view DDL twins** for retail/attendance/fundraising_ecom not
  yet generated; regenerate alongside `create_dpr_semantic_view.sql` so the
  native views match the YAMLs.
