-- Marts report: AI-generated Tracker narrative from the pre-computed brief via Snowflake Cortex
-- ---------------------------------------------------------------------------
-- Domain: DPR / cross-domain / AI narrative
-- Grain: one row per report_date
--
-- Sibling of rpt_dpr_narrative. Calls SNOWFLAKE.CORTEX.COMPLETE with the
-- structured brief from rpt_tracker_narrative_brief to produce a short
-- "Analyst Notes" block for the Memorial & Museum Daily Tracker (YTD). The
-- LLM narrates ONLY facts present in brief_json -- no invention. Structured
-- output (response_format) guarantees headline + narrative fields;
-- brief_json is stored alongside for full auditability.
--
-- DISABLED in dbt (enabled=false): this file documents the logic and is the
-- source SQL for the daily Snowflake TASK. It is NOT materialized as a view
-- because each SELECT triggers an AI call and costs tokens. The TASK reads
-- this once per morning and inserts into MARTS.TRACKER_NARRATIVE; consumers
-- read TRACKER_PBI_NARRATIVE (latest-per-date wrapper).
--
-- ADR-004: all analysis lives upstream in rpt_tracker_narrative_brief.

{{ config(enabled=false) }}
{% set system_prompt %}
You are the analyst writing the "Analyst Notes" section of the National September 11 Memorial & Museum Daily Tracker (YTD), read each morning by revenue and operations leadership.

Write 2 to 4 sentences summarizing year-to-date performance vs projection.

Rules:
- Use ONLY the figures in the JSON below. Do not invent, estimate, or compute any number that is not present. If something is not in the data, do not mention it.
- Lead with YTD Total Earned Revenue vs projection, then YTD memorial and museum attendance and tickets sold vs projection.
- The projection excludes donations and virtual-tour revenue (not budgeted); do not present the revenue variance as fully like-for-like.
- Mention the 7-day direction only when it is not flat.
- Neutral, factual, executive tone. No speculation about causes. No emojis, no bullet points, no headers.
- Format currency as $X,XXX. Format percentages as X.X%. Use "ahead of projection" / "behind projection" rather than positive/negative variance.
- Keep watch_items to genuinely notable signals (direction changes, a widening YTD gap); omit if nothing warrants attention.
{% endset %}
with brief as (
    select report_date, brief_json
    from {{ ref('rpt_tracker_narrative_brief') }}
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
                            'narrative':   {'type': 'string', 'description': 'The 2-4 sentence analyst note'},
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
    current_timestamp()                                             as generated_at,
    current_timestamp()                                             as _loaded_at
from generated
