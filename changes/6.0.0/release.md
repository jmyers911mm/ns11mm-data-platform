# 6.0.0: DPR Analyst Narrative (Cortex AI)

- **Date:** 2026-07-28
- **Version:** 6.0.0

Session date: 2026-07-28. Added an AI-generated "Analyst Notes" block to the Daily Performance
Report pipeline. A deterministic brief model computes every fact the narrative is allowed to
reference — actuals, budget, DoD, WoW, YoY (364 days), MTD/YTD, direction flags, and top movers —
then Snowflake Cortex (`claude-sonnet-4-6`) narrates ONLY those pre-computed facts. The LLM does
no analysis; it writes prose from a structured brief. Every sentence traces to an auditable input.

## Added

| Object | Type | Detail |
|--------|------|--------|
| `rpt_dpr_narrative_brief` | dbt view (MARTS) | Deterministic JSON brief: one row per report_date with actuals, budget, var_pct, dod_pct, wow_pct, yoy_pct, MTD/YTD, 7-day direction flags, and top-3 budget/DoD movers. Report date = previous day (`< CURRENT_DATE`). YoY uses 364-day (52-week) lookback for same-weekday comparison. |
| `rpt_dpr_narrative` | dbt model (disabled) | Source SQL for the daily Snowflake TASK. `enabled=false` — not materialized as a view (each SELECT triggers an AI call). Kept in project for documentation and audit. |
| `DPR_NARRATIVE` | Table (MARTS) | Append-only storage: report_date, headline, narrative, watch_items, brief_json, tokens_used, model, generated_at, `_loaded_at`. Clustered by report_date. Use `_loaded_at DESC` to pick the latest row per date (supports reprocessing). |
| `DPR_PBI_NARRATIVE` | View (MARTS) | Power BI consumption wrapper — `QUALIFY ROW_NUMBER() OVER (PARTITION BY report_date ORDER BY _loaded_at DESC) = 1`. Relates to Dim_Date on report_date. |

## Architecture

```
RPT_DPR_POWERBI (actuals) ─┐
RPT_DPR_BUDGET_DAILY        ├─► rpt_dpr_narrative_brief ─► TASK: CORTEX.COMPLETE() ─► DPR_NARRATIVE ─► DPR_PBI_NARRATIVE ─► Power BI text card
DIM_DATE ───────────────────┘        (deterministic)            (claude-sonnet-4-6)       (append-only)     (latest per date)
```

## Design decisions

| Decision | Choice |
|----------|--------|
| Report date | Previous day (`< CURRENT_DATE`) — the DPR covers yesterday |
| YoY comparator | 364 days (52 weeks) — same weekday alignment |
| Materialization | `enabled=false` in dbt; TASK owns the insert lifecycle |
| Reprocessing | Re-run the task → new `_loaded_at` wins in `DPR_PBI_NARRATIVE` |
| Structured output | `response_format` with JSON schema: `headline`, `narrative`, `watch_items` |
| Temperature | 0.1 — near-deterministic; same facts read the same way each day |
| Model | `claude-sonnet-4-6` via `SNOWFLAKE.CORTEX.COMPLETE` |
| Grants | `POWERBI_ROLE` on both table and PBI view |

## Migration notes

- **No breaking changes** to existing models or views.
- `DPR_NARRATIVE` is new infrastructure — no downstream consumers until Power BI is wired.
- The daily TASK definition is not yet created (next step: chain after DPR load task).
- `DPR_LINE_ITEMS` (legacy orphan, no dbt model) was dropped during this session.

---
