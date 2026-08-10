-- Marts report: AI-generated Today's Sales narrative from the pre-computed brief via Snowflake Cortex
-- ---------------------------------------------------------------------------
-- Domain: retail (intraday) / AI narrative
-- Grain: one row per report_date
--
-- Sibling of rpt_retail_narrative. Calls SNOWFLAKE.CORTEX.COMPLETE with the
-- structured brief from rpt_today_sales_narrative_brief to produce a short
-- "Analyst Notes" block for the Today's Sales report. The brief is INTRADAY:
-- day-to-date totals compared to the same weekday last week's full-day total.
-- The LLM narrates ONLY facts present in brief_json -- no invention.
-- Structured output (response_format) guarantees headline + narrative fields;
-- brief_json is stored alongside for full auditability.
--
-- DISABLED in dbt (enabled=false): this file documents the logic and is the
-- source SQL for the Snowflake TASK. It is NOT materialized as a view
-- because each SELECT triggers an AI call and costs tokens. The TASK reads
-- this and inserts into MARTS.TODAY_SALES_NARRATIVE; consumers read
-- TODAY_SALES_PBI_NARRATIVE (latest-per-date wrapper).
--
-- ADR-004: all analysis lives upstream in rpt_today_sales_narrative_brief.

{{ config(enabled=false) }}
{% set system_prompt %}
You are the analyst writing the "Analyst Notes" section of the National September 11 Memorial & Museum Today's Sales report, an intraday retail snapshot read by retail and operations leadership.

Write 2 to 4 sentences summarizing today's day-to-date retail sales.

Rules:
- Use ONLY the figures in the JSON below. Do not invent, estimate, or compute any number that is not present. If something is not in the data, do not mention it.
- This is an INTRADAY report: the totals are day-to-date, and the last-week baseline is that day's FULL-day total. Frame comparisons accordingly ("so far today" vs "last {weekday}'s full day") — never present the delta as a like-for-like shortfall.
- Lead with day-to-date total sales and transactions, then name the top area and top hour.
- Neutral, factual, executive tone. No speculation about causes. No emojis, no bullet points, no headers.
- Format currency as $X,XXX. Format percentages as X.X%.
- Keep watch_items to genuinely notable signals (an area far off its usual share, a large vs-last-week swing); omit if nothing warrants attention.
{% endset %}
with brief as (
    select report_date, brief_json
    from {{ ref('rpt_today_sales_narrative_brief') }}
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
