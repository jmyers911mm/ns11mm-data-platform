-- Marts report: AI-generated DPR narrative from pre-computed brief via Snowflake Cortex
-- ---------------------------------------------------------------------------
-- Domain: DPR / AI narrative
-- Grain: one row per report_date
--
-- Calls SNOWFLAKE.CORTEX.COMPLETE with the structured brief from
-- rpt_dpr_narrative_brief to produce a short "Analyst Notes" block.
-- The LLM narrates ONLY facts present in brief_json — no invention.
--
-- Structured output (response_format) guarantees headline + narrative fields.
-- brief_json is stored alongside for full auditability: every sentence traces
-- to a deterministic input.
--
-- DISABLED in dbt (enabled=false): this file exists for documentation and as
-- the source SQL for the daily Snowflake TASK. It is NOT materialized as a view
-- because each SELECT triggers an AI call and costs tokens. The TASK reads this
-- SQL once per morning and inserts into MARTS.DPR_NARRATIVE; consumers read
-- DPR_PBI_NARRATIVE (latest-per-date wrapper).
--
-- ADR-004: all analysis lives upstream in rpt_dpr_narrative_brief.

-- SYNC GUARD (7.11.0): the deployed TASK in scripts/setup_*_narrative.sql
-- embeds a COPY of the system prompt below. Any edit here must be mirrored
-- there (and the task re-created) — there is no automated drift check for
-- this pair yet.
{{ config(enabled=false) }}
{% set system_prompt %}
You are the analyst writing the "Analyst Notes" section of the National September 11 Memorial & Museum Daily Performance Report, read each morning by museum leadership.

Write 3 to 5 sentences summarizing the previous day's performance.

Rules:
- Use ONLY the figures in the JSON below. Do not invent, estimate, or compute any number that is not present. If something is not in the data, do not mention it.
- Lead with Total Estimated Revenue vs budget, then name the 1-2 biggest drivers from top_budget_movers / top_dod_movers.
- Prefer same-day-prior-week (wow_pct) over day-over-day when describing attendance and retail, since weekdays differ structurally.
- Use year-over-year (yoy_pct, 364 days / 52 weeks prior) to contextualize whether performance is trending above or below the prior-year baseline. Mention YoY when it diverges materially (>10%) from budget variance direction.
- If is_commemoration_day or in_commemoration_window is true, explicitly note that elevated figures reflect the commemoration period, not underlying trend.
- When a line item has no budget (budget is null), describe it in absolute terms or vs prior period only.
- Neutral, factual, executive tone. No speculation about causes beyond what the movers show. No emojis, no bullet points, no headers.
- Format currency as $X,XXX. Format percentages as X.X%. Use "ahead of budget" / "behind budget" rather than positive/negative variance.
- Keep watch_items to genuinely notable signals (7-day direction changes, large WoW swings, significant YoY divergence); omit if nothing warrants attention.
{% endset %}
with brief as (
    select report_date, brief_json
    from {{ ref('rpt_dpr_narrative_brief') }}
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
                            'headline': {
                                'type': 'string',
                                'description': 'One-line summary suitable for a card title, max 12 words'
                            },
                            'narrative': {
                                'type': 'string',
                                'description': 'The 3-5 sentence analyst note'
                            },
                            'watch_items': {
                                'type': 'array',
                                'items': {'type': 'string'},
                                'description': 'Optional: 0-3 short items worth monitoring'
                            }
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
    raw_response:structured_output[0]:raw_message:narrative::string   as narrative,
    raw_response:structured_output[0]:raw_message:watch_items         as watch_items,
    raw_response:usage:total_tokens::int                              as tokens_used,
    'claude-sonnet-4-6'                                               as model,
    current_timestamp()                                               as generated_at,
    current_timestamp()                                               as _loaded_at
from generated