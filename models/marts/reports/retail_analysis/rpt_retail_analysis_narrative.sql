-- Marts report: AI-generated Retail Analysis narrative from the pre-computed brief via Snowflake Cortex
-- ---------------------------------------------------------------------------
-- Domain: retail / AI narrative
-- Grain: one row per report_date
--
-- Twin of rpt_retail_narrative and rpt_carts_narrative. Calls
-- SNOWFLAKE.CORTEX.COMPLETE with the structured brief from
-- rpt_retail_analysis_narrative_brief to produce a short "Analyst Notes" block
-- for the Retail Analysis Report. The LLM narrates ONLY facts present in
-- brief_json -- no invention. Structured output (response_format) guarantees
-- headline + narrative fields; brief_json is stored alongside for full
-- auditability.
--
-- DISABLED in dbt (enabled=false): this file documents the logic and is the
-- source SQL for the daily Snowflake TASK. It is NOT materialized as a view
-- because each SELECT triggers an AI call and costs tokens. The TASK reads
-- this once per morning and inserts into MARTS.RETAIL_ANALYSIS_NARRATIVE;
-- consumers read RETAIL_ANALYSIS_PBI_NARRATIVE (latest-per-date wrapper).
--
-- ADR-004: all analysis lives upstream in rpt_retail_analysis_narrative_brief.

-- SYNC GUARD: when this narrative is promoted to a deployed TASK, the task DDL
-- in scripts/setup_retail_analysis_narrative.sql will embed a COPY of the
-- system prompt below. Any edit here must be mirrored there (and the task
-- re-created) -- there is no automated drift check for this pair yet. The task
-- script is NOT shipped in 8.10.0: the Cortex surface is created only after the
-- report family has run clean for a cycle, matching how 7.11.0 sequenced the
-- retail and carts narratives.
{{ config(enabled=false) }}
{% set system_prompt %}
You are the analyst writing the "Analyst Notes" section of the National September 11 Memorial & Museum Retail Analysis Report, a workbook distributed to museum leadership and the retail and finance teams.

Write 3 to 5 sentences summarizing the previous day's retail analysis.

Rules:
- Use ONLY the figures in the JSON below. Do not invent, estimate, or compute any number that is not present. If something is not in the data, do not mention it.
- The report covers four selling blocks: Museum Store, Preview Site / Vesey Street, E-Commerce, and Memorial Carts. Lead with Museum Store sales and profit versus budget, then name the 1-2 biggest drivers from top_budget_movers / top_dod_movers.
- The `ratios` object carries capture rate, conversion rate and average sale with their numerator and denominator. Quote the `actual` value; use the numerator and denominator only to explain WHY a rate moved (for example, capture fell because attendance rose faster than store visitors). Never re-derive a rate from figures in `metrics`.
- Prefer same-day-prior-week (wow_pct) over day-over-day when describing sales and traffic, since weekdays differ structurally.
- Use year-over-year (yoy_pct, 364 days / 52 weeks prior) to contextualize whether performance is trending above or below the prior-year baseline. Mention YoY when it diverges materially (>10%) from budget variance direction.
- If is_commemoration_day or in_commemoration_window is true, explicitly note that elevated figures reflect the commemoration period, not underlying trend.
- Every line named in `unavailable_lines` has no source in the platform today. Never mention it, and never describe it as zero.
- When a line item has no budget (budget is null), describe it in absolute terms or vs prior period only. E-Commerce figures cover the CounterPoint order channel only.
- Neutral, factual, executive tone. No speculation about causes beyond what the movers show. No emojis, no bullet points, no headers.
- Format currency as $X,XXX. Format percentages as X.X%. Use "ahead of budget" / "behind budget" rather than positive/negative variance.
- Keep watch_items to genuinely notable signals (7-day direction changes, large WoW swings, significant YoY divergence); omit if nothing warrants attention.
{% endset %}
with brief as (
    select report_date, brief_json
    from {{ ref('rpt_retail_analysis_narrative_brief') }}
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
