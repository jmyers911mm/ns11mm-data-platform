# Report Lineage Index

> **Scope:** every live report family in `models/marts/reports/`, from source extract to
> the Power BI surface.
> **Source of truth:** built from the actual repo models (`ns11mm/ns11mm-data-platform`, v7.13.0)
> **Last updated:** August 2026 · Jeremy Myers, VP of AI & Analytics

One page per **report family**, matching the ADR-021 directory structure. A family is a
report cluster, not a domain — `tracker` is separate from `dpr` even though it reads the
DPR's wrapper, because it is a distinct printed artifact with its own layout catalog.

| Family | Page | Models | Backing fact | Semantic view |
| --- | --- | --- | --- | --- |
| **DPR** | [`../DPR_LINEAGE.md`](../DPR_LINEAGE.md) | 13 | `fct_daily_performance` | `MARTS.DPR` (49 metrics) |
| **Retail** | [`RETAIL_LINEAGE.md`](RETAIL_LINEAGE.md) | 20 | `fct_retail_daily`, `fct_retail_performance` | `MARTS.RETAIL` (14 metrics) |
| **Tracker** | [`TRACKER_LINEAGE.md`](TRACKER_LINEAGE.md) | 8 | — (projects the DPR wrapper) | via `MARTS.DPR` |
| **Scan** | [`SCAN_LINEAGE.md`](SCAN_LINEAGE.md) | 5 | `fct_daily_scan` | `MARTS.ATTENDANCE` (table `DS`) |
| **Today's Sales** | [`TODAY_SALES_LINEAGE.md`](TODAY_SALES_LINEAGE.md) | 5 | `fct_today_sales_hourly` | `MARTS.ATTENDANCE` (table `TS`) |
| **Attendance** | [`ATTENDANCE_LINEAGE.md`](ATTENDANCE_LINEAGE.md) | 6 | `fct_daily_performance` + Sensource | **none** — see the page |
| **Website Commerce** | [`WEBSITE_COMMERCE_LINEAGE.md`](WEBSITE_COMMERCE_LINEAGE.md) | 3 | — (reads staging directly) | **none** — scaffold only |

`models/marts/reports/restricted/` (`rpt_wifi_email_export`) has no lineage page. It is a
single-model PII extract with a least-privilege grant and, by design, no semantic view;
see [`../DATA_CLASSIFICATION.md`](../DATA_CLASSIFICATION.md).

---

## The shape every family shares

Under **ADR-021** each serving model takes one of seven roles, identified by its filename
suffix, and may read only *leftward* through this chain:

```
semantic view
   └── *_powerbi ──┬── *_report_long / *_periods ── *_print
                   ├── *_period_windows ───────────┘
                   ├── *_narrative_brief ── *_narrative / *_narrative_card
                   └── *_excel_export
   *_budget_daily / *_conform ── (joins into the shapes above)
```

| Suffix | Role | One-line rule |
| --- | --- | --- |
| `*_powerbi` | Wrapper | The only permitted `SEMANTIC_VIEW()` caller. Projection and aliasing, nothing else |
| `*_budget_daily`, `*_conform` | Comparison conform | Align the budget / prior-year / cross-domain side to the wrapper's column names |
| `*_period_windows` | Period definition | Printed periods as date ranges. No measures |
| `*_report_long`, `*_periods`, `*_mtd_ytd_long` | Serving shape | Unpivot and re-aggregate governed measures at display grain. Never a pre-divided ratio |
| `*_print`, `*_excel_export` | Presentation shape | Match a legacy artifact row-for-row. No new aggregation |
| `*_narrative_brief` | Deterministic brief | One JSON object per date. No LLM call |
| `*_narrative`, `*_narrative_card` | Narrative render | `*_narrative` is the gated Cortex call; `*_narrative_card` is deterministic SQL. No number absent from the brief |

**Three rules cut across every family**, and they are where the wrong answers hide:

1. **Ratios are never stored pre-divided.** A serving shape carries numerator and
   denominator; the division happens once, at the grain being displayed. This is what makes
   an MTD ratio a ratio-of-sums rather than an average of daily ratios.
2. **Composites are authored once.** Preferred home is a semantic-view metric, then a
   wrapper column, then one serving model everything reads. Two arithmetically identical
   copies is still a defect.
3. **Placeholders are typed NULLs with a stated cause** — blocked on a business rule,
   pending an upstream addition, or no data feed. Never omitted, never zero-filled, never
   guessed. Row-level equivalents carry `availability = 'Stub'` in the layout seed.

---

## How to read any of these pages

Each page opens with a mermaid graph of the whole chain — staging, intermediate, fact,
semantic view, serving models — then a model inventory with roles and grains, then the
transformations that actually change numbers, then the caveats.

If you are chasing a specific number, start at the bottom of the graph and walk up. If you
are about to add a model, read the role table above first — naming it correctly is what
makes it compliant, and ADR-021 exists so that no ADR amendment is needed per report.

---

## Cross-family seams worth knowing

These are the places where one family reaches into another. All are intentional and all
are single-authored, but they are the joins most likely to surprise you.

| Seam | Direction | Why |
| --- | --- | --- |
| `rpt_dpr_retail_conform` | DPR reads `fct_retail_daily` | The MTD/YTD workbooks print retail detail the DPR fact does not carry |
| `rpt_retail_report_long` | Retail reads `fct_daily_performance` | Museum attendance is the denominator of the retail capture rate |
| `rpt_tracker_powerbi` / `rpt_tracker_budget_daily` | Tracker reads the DPR wrapper and budget conform | The Tracker has no fact of its own |
| `dim_facility` (from `seed_facility_area`) | Everything retail-shaped | Selling areas are resolved by conformed name, never by raw `key_facility` |
| `dim_date.week_bucket` / `bucket_sort` | Tracker matrix | Week-bucket logic folded onto the date dimension in 7.12.2 rather than living in its own view |

---

## Cross-family patterns

**The narrative chain is the same everywhere.** A `*_narrative_brief` view emits one JSON
object per date, deterministically. A `*_narrative` model holds the Cortex call and is
`enabled=false` — each `SELECT` would cost tokens — existing as documentation and as the
source SQL for a Snowflake task created by `scripts/setup_<family>_narrative.sql`. Every
task runs at **05:30 ET** on `MONITORING_WH` and is **created suspended**. Consumers read
the `*_PBI_NARRATIVE` wrapper view.

The same caveat applies to all of them: **the deployed task embeds a copy of the system
prompt, and there is no automated drift check for that pair.** Edit both or neither.

Two families also carry a `*_narrative_card` — deterministic SQL rendering a fixed-width
ASCII card, so the surface works under DirectQuery without `Value.NativeQuery` or DAX text
assembly, and works whether or not the Cortex task is running.

**Layout catalogs live with their family.** Eight `dim_*_line_item` / `dim_*_print_line`
models moved out of `models/marts/dimensions/` in 7.13.0, and their seeds into
`seeds/report_layout/`. They are materialized as tables while everything else in
`reports/` is a view.

**Padded sort labels are load-bearing.** `dim_retail_print_line` and
`dim_dpr_mtd_ytd_print_line` append occurrence-index trailing spaces to repeated labels so
Power BI's sort-by-column, which requires a 1:1 label-to-sort mapping, accepts them. The
padding is invisible in rendering. Removing it silently breaks row order.

---

## Open items across all families

| Item | Families affected |
| --- | --- |
| **ADR-021 is `Proposed`** — §3 needs Data & AI Committee ratification, and ~20 models depend on it | all |
| **Memorial-vs-museum revenue split** (ADR-005) blocks typed-NULL columns | tracker, dpr |
| **Fiscal calendar** undefined — every period window is calendar-only | dpr, retail, tracker |
| **Sensource / Shopify feeds** not landed — every visitor-derived ratio resolves NULL | retail, attendance, dpr (via retail conform) |
| **Exposures registry stale** — `models/exposures.yml` still points at facts and legacy models, not at the serving stacks built in 7.10.0–7.13.0 | all |
| **Window definitions not yet validated** against the legacy `.prpt` files | dpr, retail |

---

## Related documents

- **Platform-wide flow:** [`../ARCHITECTURE_FLOW.md`](../ARCHITECTURE_FLOW.md)
- **Role grammar:** [`../../adr/ADR_021_report_serving_layer.md`](../../adr/ADR_021_report_serving_layer.md)
- **Materialization policy:** [`../../adr/ADR_020_materialization_policy.md`](../../adr/ADR_020_materialization_policy.md)
- **Metric ownership:** [`../../adr/ADR_018_metric_definition_ownership.md`](../../adr/ADR_018_metric_definition_ownership.md)
- **Report → semantic view map:** [`../../../models/marts/reports/report_semantic_view_map.md`](../../../models/marts/reports/report_semantic_view_map.md)
- **Building a new report:** [`../BUILD_DIMS_METS.md`](../BUILD_DIMS_METS.md)
