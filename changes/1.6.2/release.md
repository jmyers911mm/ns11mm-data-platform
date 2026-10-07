# 1.6.2: Report-Estate Ingestion Batch 2: Sensource, Budgets, WiFi-Table Correction

- **Date:** 2026-07-15
- **Version:** 1.6.2

Loaded and wired the remaining five report-estate source tables. Eight of the
nine report-estate stubs now carry real data (four in 1.6.1, four here); the
retail and daily-scan budget feeds unblock every `_budget` / variance column
across the estate (ADR-005). One upload was misnamed at source and is handled
accordingly (see below). Follows the seed-swap pattern from 1.6.0 / 1.6.1.

## Added — staging models (`models/raw/`)

Built against the actual uploaded columns (reconciled against the workbook,
several differed from the documented schema):

- **`stg_sensource__visitors`** — Sensource entries/exits by facility. Real feed
  adds `acp` and `passes_scanned` beyond the documented `num_entry/num_exit`.
- **`stg_sensource__attendance`** — daily attendance. Real feed is
  **pre-aggregated by named area** (`mem_attendance`, `mus_attendance`,
  `memorial_only`, `mus_store`, `mus_store_vesey`), not by facility as the
  transform docs implied — simpler, no facility mapping needed.
- **`stg_budget__retail`** — retail budget/forecast by facility/day
  (`fact_retail_forecasts`); adds `avg_don_mem_only_vis`. `key_facility` is a
  numeric facility code (e.g. 1003).
- **`stg_budget__daily_scan`** — daily-scan budget, wide by market segment
  (`fact_dsr_forecasts`); adds `mobile` and `gocity` segments. Decimal forecast
  values; literal `'NULL'` strings nullified via `try_to_decimal`.
- **`stg_dpr__daily_metrics_wide`** — see correction below.

## Added — RAW sources

- Five table entries added to the `report_estate_seed` source group:
  `seed_sensource_visitors`, `seed_sensource_attendance`, `seed_retail_budget`,
  `seed_dsr_budget`, `seed_wifi_audience`.

## Changed — stub → real source

- **`int_retail__visitors`** — Sensource half now reads
  `stg_sensource__visitors`; `visitor_count = sum(num_entry)`.
- **`rpt_attendance`** — now reads `stg_sensource__attendance` directly (the
  feed is already pre-aggregated by area), replacing the interim facility-based
  mapping.
- **`fct_retail_performance`** — budget seam now reads `stg_budget__retail`
  (`revenue_budget` → net_sales seam, `profit_budget` → net_profit seam).
- **`fct_daily_scan`** — budget now reads `stg_budget__daily_scan`, unpivoted
  from the wide segment columns to `segment_key` to match the fact grain
  (keys align with `seed_scan_market_segment`).

## Correction — `seed_wifi_audience` is not a WiFi email list

The uploaded `seed_wifi_audience` is **not** the Blue State email audience. It is
a **wide daily DPR-metrics table** (56 columns: attendance, ticket/pass revenue,
every tour line, retail gross profit, donations, operating expenses, civic
programs) with a single `daily_wifi_visitors` column and **no email addresses or
names**. Handled by:

- **`stg_dpr__daily_metrics_wide`** (renamed from the planned
  `stg_wifi__audience`) — conforms it faithfully and exposes it as an
  independent daily-metrics **reconciliation source** for parity-checking the
  built DPR marts.
- **`rpt_wifi_email_export` remains stubbed.** The real governed PII source
  (`stage_acceptance_uap_daily`: email / first / last, filtered to accepted-AUP
  rows) has **not** been loaded. This is now the only report-estate report with
  no real feed.

## Still stubbed (no data yet)

- `tmp_seed_wifi__audience` — real `stage_acceptance_uap_daily` audience feed
  (email/name) still needed for `rpt_wifi_email_export`.

## Deploy

```
dbt build --select source:report_estate_seed+ --target dev
```

## Known Issues / Verify after deploy

- **Daily-scan budget segment keys** — the DSR wide→long unpivot maps columns to
  `segment_key` values (`citypass`, `c3`, `newyork`, `walkup`, `gocity`, …);
  confirm they match `seed_scan_market_segment.segment_key`
  (`select segment_key, sum(passes_budget) from fct_daily_scan group by 1`; an
  all-null budget column signals a key mismatch). Note `partners`, `mobile`, and
  `total_tickets` from the source have no scan segment and are intentionally not
  mapped.
- **Retail budget facility codes** — `stg_budget__retail.key_facility` is numeric
  (1003, …); confirm it matches `seed_facility_area` / `fct_retail_performance`
  keys, not names.
- **Sensource attendance area labels** — confirm `mus_store` vs
  `mus_store_vesey` correspond to the intended report lines.
- **`stg_dpr__daily_metrics_wide`** is a reconciliation source, not wired into
  any report; use it to validate DPR marts, then decide whether to retain.
