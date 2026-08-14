-- Marts report: AI-generated Donations Analysis narrative from the pre-computed brief via Snowflake Cortex
-- ---------------------------------------------------------------------------
-- Domain: donations / AI narrative
-- Grain: one row per report_date
--
-- Twin of rpt_retail_narrative and rpt_dpr_narrative. Calls
-- SNOWFLAKE.CORTEX.COMPLETE with the structured brief from
-- rpt_donations_narrative_brief to produce a short "Analyst Notes" block for
-- the Donations Analysis Report. The LLM narrates ONLY facts present in
-- brief_json -- no invention. Structured output (response_format) guarantees
-- headline + narrative fields; brief_json is stored alongside for full
-- auditability.
--
-- DISABLED in dbt (enabled=false): this file documents the logic and is the
-- source SQL for the daily Snowflake TASK. It is NOT materialized as a view
-- because each SELECT triggers an AI call and costs tokens. The TASK reads this
-- once per morning and inserts into MARTS.DONATIONS_NARRATIVE; consumers read
-- DONATIONS_PBI_NARRATIVE (latest-per-date wrapper).
--
-- ADR-004: all analysis lives upstream in rpt_donations_narrative_brief.

-- SYNC GUARD: when this model is enabled, the deployed TASK in
-- scripts/setup_donations_narrative.sql will embed a COPY of the system prompt
-- below. Any edit here must be mirrored there (and the task re-created) — there
-- is no automated drift check for this pair yet.
{{ config(enabled=false) }}
{% set system_prompt %}
You are the analyst writing the "Analyst Notes" section of the National September 11 Memorial & Museum Donations Analysis Report, read by the development and visitor services teams.

Write 3 to 5 sentences summarizing the previous day's visitor-facing donation performance.

Rules:
- Use ONLY the figures in the JSON below. Do not invent, estimate, or compute any number that is not present. If something is not in the data, do not mention it.
- Lead with Ticketing Donations, then name the 1-2 biggest drivers from top_wow_movers / top_dod_movers (typically Museum Store, the donation carts, Coat Check or Museum Exit).
- Prefer same-weekday-last-week (wow_pct) over day-over-day when describing donation volume, since donation lines are strongly weekday-shaped.
- Use year-over-year (yoy_pct, 364 days prior) to say whether the day is trending above or below the prior-year baseline. Mention it when it diverges materially (>10%) from the week-over-week direction.
- Per-visitor figures in per_visitor are dollars per visitor. Quote them only alongside the attendance figure they divide by, so a per-cap move driven by attendance is never presented as a donor-behaviour move.
- If is_commemoration_day or in_commemoration_window is true, explicitly note that elevated figures reflect the commemoration period, not underlying trend.
- This report has NO budget. Never describe anything as ahead of or behind budget, plan, goal or forecast.
- Do not state or imply a total across donation sources. The report publishes no certified cross-source total and the individual lines must not be added together.
- Anything listed in data_gaps is a known coverage limit. Do not narrate it as a decline and do not treat a missing line as zero.
- Neutral, factual, executive tone. No speculation about causes beyond what the movers show. No emojis, no bullet points, no headers.
- Format currency as $X,XXX. Format per-visitor figures as $X.XX. Format percentages as X.X%.
- Keep watch_items to genuinely notable signals (7-day direction changes, large week-over-week swings, significant year-over-year divergence); omit if nothing warrants attention.
{% endset %}
with brief as (
    select report_date, brief_json
    from {{ ref('rpt_donations_narrative_brief') }}
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
