-- Marts report: AI-generated Earned Income Variance narrative from the pre-computed brief via Snowflake Cortex
-- ---------------------------------------------------------------------------
-- Domain: earned income / AI narrative
-- Grain: one row per report_date
--
-- Twin of rpt_dpr_narrative and rpt_retail_analysis_narrative. Calls
-- SNOWFLAKE.CORTEX.COMPLETE with the structured brief from
-- rpt_earned_income_variance_narrative_brief to produce a short "Analyst Notes"
-- block for the Earned Income Variance Report. The LLM narrates ONLY facts
-- present in brief_json -- no invention. Structured output (response_format)
-- guarantees headline + narrative fields; brief_json is stored alongside for
-- full auditability.
--
-- DISABLED in dbt (enabled=false): this file documents the logic and is the
-- source SQL for the daily Snowflake TASK. It is NOT materialized as a view
-- because each SELECT triggers an AI call and costs tokens. The TASK reads this
-- once per morning and inserts into MARTS.EARNED_INCOME_VARIANCE_NARRATIVE;
-- consumers read EARNED_INCOME_VARIANCE_PBI_NARRATIVE (latest-per-date wrapper).
--
-- AUDIENCE NOTE: this report's distribution list is the CFO and the finance
-- leadership group. The prompt is deliberately stricter than the retail and DPR
-- narratives on two points -- it may not describe an unavailable line as zero,
-- and it must state that operating expenses are absent whenever it would
-- otherwise imply a net earned-income position. Do not relax either rule
-- without the sign-off in DECISION_MEMO.md.
--
-- ADR-004: all analysis lives upstream in rpt_earned_income_variance_narrative_brief.

-- SYNC GUARD: when this narrative is promoted to a deployed TASK, the task DDL
-- in scripts/setup_earned_income_variance_narrative.sql will embed a COPY of the
-- system prompt below. Any edit here must be mirrored there (and the task
-- re-created) -- there is no automated drift check for this pair yet. The task
-- script is NOT shipped in 8.11.0: the Cortex surface is created only after the
-- report family has run clean for a cycle, matching how 7.11.0 sequenced the
-- retail and carts narratives and how 8.9.0 / 8.10.0 sequenced theirs.
{{ config(enabled=false) }}
{% set system_prompt %}
You are the analyst writing the "Analyst Notes" section of the National September 11 Memorial & Museum Earned Income Variance Report, a workbook distributed to the Chief Financial Officer and the finance and operations leadership group.

Write 3 to 5 sentences summarizing the previous day's earned income against forecast.

Rules:
- Use ONLY the figures in the JSON below. Do not invent, estimate, or compute any number that is not present. If something is not in the data, do not mention it.
- Lead with Total Admissions Revenue against budget, then Total Tickets Sold, then name the 1-2 biggest drivers from top_budget_movers.
- The `ratios` object carries average ticket price with its numerator and denominator. Quote the `actual` value; use the numerator and denominator only to explain WHY it moved (for example, average ticket price fell because ticket volume grew faster than ticket revenue). Never re-derive it from figures in `metrics`.
- Every metric object carries both var_amount (dollars or units) and var_pct. Quote the dollar variance for revenue lines and the unit variance for count lines; use the percentage as support, not as the headline.
- Prefer same-day-prior-week (wow_pct) over day-over-day when describing volume, since weekdays differ structurally.
- Use year-over-year (yoy_pct, 364 days / 52 weeks prior) to contextualize whether performance is trending above or below the prior-year baseline. Mention YoY when it diverges materially (>10%) from the budget variance direction.
- If is_commemoration_day or in_commemoration_window is true, explicitly note that elevated figures reflect the commemoration period, not underlying trend.
- Every line named in `unavailable_lines` has no source in the platform today. Never mention it and never describe it as zero. If the note would otherwise read as a statement about net earned income or profitability, add one clause saying operating expenses are not included in this report.
- Every line named in `partial_lines` is produced from a subset of its legacy components. If you name one of those lines, describe it as a partial figure once. Do not repeat the caveat on every line.
- When a line has no budget (budget is null), describe it in absolute terms or against prior period only.
- Neutral, factual, executive tone. No speculation about causes beyond what the movers show. No emojis, no bullet points, no headers.
- Format currency as $X,XXX. Format percentages as X.X%. Use "ahead of forecast" / "behind forecast" rather than positive/negative variance.
- Keep watch_items to genuinely notable signals (7-day direction changes, large WoW swings, significant YoY divergence); omit if nothing warrants attention.
{% endset %}
with brief as (
    select report_date, brief_json
    from {{ ref('rpt_earned_income_variance_narrative_brief') }}
),
generated as (
    select
        b.report_date,
        b.brief_json,
        snowflake.cortex.complete(
            'claude-sonnet-4-6',
            array_construct(
                object_construct('role', 'system', 'content', $${{ system_prompt }}$$),
                object_construct('role', 'user',   'content', b.brief_json::string)
            ),
            {
                'response_format': {
                    'type': 'json',
                    'schema': {
                        'type': 'object',
                        'properties': {
                            'headline':    {'type': 'string', 'description': 'One-line summary suitable for a card title, max 12 words'},
                            'narrative':   {'type': 'string', 'description': 'The 3-5 sentence analyst note'},
                            'watch_items': {'type': 'array', 'items': {'type': 'string'}, 'description': 'Optional: 0-3 short items worth monitoring'}
                        },
                        'required': ['headline', 'narrative']
                    }
                },
                'max_tokens': 600,
                'temperature': 0.1
            }
        ) as raw_response
    from brief b
)
select
    report_date,
    brief_json,
    raw_response:structured_output[0]:raw_message:headline::string   as headline,
    raw_response:structured_output[0]:raw_message:narrative::string  as narrative,
    raw_response:structured_output[0]:raw_message:watch_items        as watch_items,
    raw_response:usage:total_tokens::int                             as tokens_used,
    'claude-sonnet-4-6'                                              as model,
    current_timestamp()                                              as generated_at,
    current_timestamp()                                              as _loaded_at
from generated
