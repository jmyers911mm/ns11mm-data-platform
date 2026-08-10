-- Marts report: deterministic narrative brief — pre-computed Attendance facts for the AI_COMPLETE prompt
-- ---------------------------------------------------------------------------
-- Domain: attendance / AI narrative
-- Grain: one row per report_date
--
-- Sibling of rpt_dpr_narrative_brief for the Attendance Report cluster
-- (Attendance Report + Daily Attendance Report). One JSON object per
-- report_date with every fact the note may reference: memorial/museum
-- attendance and the memorial-only plaza count, day-over-day and
-- same-weekday-last-week deltas, same-date-last-year comparison, a trailing
-- 7-day direction flag, and the commemoration-window guard. Store visitor
-- counts are Sensource-stubbed zeros today, so they are deliberately NOT in
-- the brief — the LLM cannot narrate a stub. The LLM narrates ONLY this
-- brief — it does not analyze. Every sentence traces to a field here.
--
-- ADR-004: all analysis logic lives in this model, not the prompt or Power BI.

{{ config(materialized='view') }}

with a as (
    select
        date_value as report_date,
        is_commemoration_day,
        memorial_attendance,
        museum_attendance,
        memorial_only
    from {{ ref('rpt_attendance') }}
),

-- Deltas from the day-grain spine: prior day, same weekday last week,
-- trailing 7-day mean vs the prior 7-day mean (direction flag)
deltas as (
    select
        report_date,
        is_commemoration_day,
        memorial_attendance,
        museum_attendance,
        memorial_only,
        lag(memorial_attendance, 1) over (order by report_date)  as mem_prior_day,
        lag(museum_attendance, 1)  over (order by report_date)   as mus_prior_day,
        lag(memorial_attendance, 7) over (order by report_date)  as mem_last_week,
        lag(museum_attendance, 7)  over (order by report_date)   as mus_last_week,
        avg(museum_attendance) over (
            order by report_date rows between 6 preceding and current row
        )                                                        as mus_avg_7d,
        avg(museum_attendance) over (
            order by report_date rows between 13 preceding and 7 preceding
        )                                                        as mus_avg_prior_7d
    from a
),

-- Same calendar date last year (join, not lag: the spine may have gaps)
yoy as (
    select
        d.report_date,
        p.memorial_attendance as mem_last_year,
        p.museum_attendance   as mus_last_year
    from deltas d
    left join a p on p.report_date = dateadd('year', -1, d.report_date)
),

brief as (
    select
        d.report_date,
        object_construct(
            'report_date', d.report_date::varchar,
            'day_name', dayname(d.report_date),
            'is_commemoration_day', d.is_commemoration_day,
            'in_commemoration_window',
                (month(d.report_date) = 9 and day(d.report_date) between 6 and 16),

            'attendance', object_construct(
                'memorial', d.memorial_attendance,
                'museum', d.museum_attendance,
                'memorial_only', d.memorial_only
            ),

            'vs_prior_day', object_construct(
                'memorial_delta', d.memorial_attendance - d.mem_prior_day,
                'museum_delta', d.museum_attendance - d.mus_prior_day
            ),

            'vs_same_weekday_last_week', object_construct(
                'memorial_delta', d.memorial_attendance - d.mem_last_week,
                'memorial_pct', round(div0(
                    d.memorial_attendance - d.mem_last_week,
                    nullif(d.mem_last_week, 0)), 4),
                'museum_delta', d.museum_attendance - d.mus_last_week,
                'museum_pct', round(div0(
                    d.museum_attendance - d.mus_last_week,
                    nullif(d.mus_last_week, 0)), 4)
            ),

            'vs_same_date_last_year', object_construct(
                'memorial_delta', d.memorial_attendance - y.mem_last_year,
                'memorial_pct', round(div0(
                    d.memorial_attendance - y.mem_last_year,
                    nullif(y.mem_last_year, 0)), 4),
                'museum_delta', d.museum_attendance - y.mus_last_year,
                'museum_pct', round(div0(
                    d.museum_attendance - y.mus_last_year,
                    nullif(y.mus_last_year, 0)), 4)
            ),

            'direction_7d', object_construct(
                'museum_attendance', case
                    when d.mus_avg_prior_7d is null then 'insufficient_history'
                    when d.mus_avg_7d > d.mus_avg_prior_7d * 1.05 then 'rising'
                    when d.mus_avg_7d < d.mus_avg_prior_7d * 0.95 then 'falling'
                    else 'flat'
                end
            )
        ) as brief_json
    from deltas d
    left join yoy y on d.report_date = y.report_date
)

select report_date, brief_json from brief
