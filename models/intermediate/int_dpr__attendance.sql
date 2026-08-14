-- Silver intermediate: museum and memorial attendance (legacy rules)
-- ---------------------------------------------------------------------------
-- Domain: attendance
-- Grain: one row per date_key
--
-- The single authored home for the DPR / Attendance Report attendance lines.
-- Museum attendance sums the signed passes-scanned contribution from
-- int_ticket_scans through seed_attendance_facility_group and applies the legacy
-- "closed day" zeroing rule from seed_attendance_zeroing_rule. Memorial
-- attendance sums stg_memorial__attendance, its own legacy table, at the seeded
-- memorial key_facility. Feeds fct_daily_performance.mus_attendance and
-- .mem_attendance (and, through them, rpt_attendance, rpt_daily_attendance,
-- rpt_dpr_* and every per-capita ratio).
--
-- Legacy lineage: t_fact_museum_passes_scanned (fact_visitors.passes_scanned),
-- t_reporting_mus_attendance, t_reporting_mem_attendance
-- (911dw.memorial_attendance), t_fact_attendance_all_locations,
-- t_fact_attendance_all_facilities.
--
-- SCOPE NOTE (ADR-005 gate) — owner Chris Wogas. Three definitional changes,
-- all of which move published numbers. See DECISION_MEMO.
--
-- * CLASSIFICATION. Museum vs. memorial is no longer inferred from
--   stg_gateway__facility.facility_name ('%MEMORIAL%' / '%MUSEUM%'). It is the
--   legacy numeric key_facility map, seeded: museum = 1006, 3000; memorial =
--   2000. The legacy estate is internally inconsistent about memorial --
--   t_fact_attendance_all_locations and t_fact_attendance_all_facilities use
--   key_facility IN (2000) while t_reporting_mem_attendance and
--   t_fact_mus_store_analysis use IN (1000,2000). 2000 is the chosen definition;
--   1000 is carried in the seed with is_primary_definition = FALSE and is not
--   counted. Flip the seed, not this model, if the decision goes the other way.
--
-- * MUSEUM ATTENDANCE now means scanned passes at the museum facilities, with
--   the legacy closed-day zeroing applied. It previously came from
--   int_dpr__admissions as GA ticket QUANTITY, which is a tickets-issued count,
--   not a gate count, and carried no zeroing rule. mus_attendance is defined
--   ONCE, here; int_dpr__admissions no longer publishes an attendance column.
--
-- * MEMORIAL ATTENDANCE has a feed. It reads stg_memorial__attendance
--   (911dw.memorial_attendance, staged in 8.4.0), which is the table every
--   legacy reader uses -- t_fact_attendance_all_locations.sql:14-19,
--   t_fact_attendance_all_facilities.sql:10-15, t_reporting_mem_attendance.sql:
--   8-12. It is NOT the Gateway scan feed and never was: a sample of
--   911dw.fact_visitors confirms neither of its writers can emit key_facility
--   2000 (t_fact_museum_passes_scanned emits only 1006, 5000 and 0; the
--   Sensource API leg covers ParentFacility 1000-1009). The value the platform
--   published before this release was a facility-name pattern artefact; the
--   value it publishes now is the legacy measure. NULL survives only where the
--   feed has no row for a day -- never coalesced to 0, because a zero would be
--   indistinguishable from a genuine no-visitor day.
--
-- NOTE (double-writer guard): mem_passes_scanned_gateway is a MONITOR, not a
-- measure. It must stay NULL. If a Gateway ACP is ever mapped to key_facility
-- 2000 in seed_gateway_facility_map, memorial attendance would have two writers
-- and would double count; this column makes that visible on the day it happens.
-- It is deliberately excluded from uncounted_passes_scanned so the monitor
-- totals stay mutually exclusive.
--
-- ADR-004: all business logic lives here, not in Power BI.

{{ config(materialized='view') }}

with scans as (
    select
        scan_date                                                          as date_key,
        key_facility,
        net_visitor_count
    from {{ ref('int_ticket_scans') }}
    where is_counted_scan
      and scan_date is not null
),

memorial_feed as (
    select
        business_date                                                      as date_key,
        key_facility,
        passes_scanned
    from {{ ref('stg_memorial__attendance') }}
    where business_date is not null
),

facility_group as (
    select
        key_facility,
        attendance_group
    from {{ ref('seed_attendance_facility_group') }}
    where is_primary_definition
),

zeroing_rule as (
    select
        rule_key,
        rule_type,
        day_of_week_name,
        exception_date,
        min_threshold
    from {{ ref('seed_attendance_zeroing_rule') }}
    where attendance_group = 'museum'
),

classified as (
    select
        s.date_key,
        coalesce(g.attendance_group, 'unmapped')                           as attendance_group,
        s.net_visitor_count
    from scans s
    left join facility_group g on s.key_facility = g.key_facility
),

scan_daily as (
    select
        date_key,
        -- No `else 0`: a day with no museum scan rows at all yields NULL, which
        -- is the absence signal, not a real zero.
        sum(case when attendance_group = 'museum'   then net_visitor_count end)   as mus_passes_scanned,
        -- Monitor only. Must be NULL -- see the double-writer guard above.
        sum(case when attendance_group = 'memorial' then net_visitor_count end)   as mem_passes_scanned_gateway,
        -- Everything the two attendance definitions do not claim: Gateway
        -- facility 12 -> key_facility 5000 ('none') and the legacy else '0'
        -- bucket ('unmapped'). Monitored so a newly-added gate is visible.
        sum(case when attendance_group not in ('museum', 'memorial')
                 then net_visitor_count end)                                      as uncounted_passes_scanned
    from classified
    group by date_key
),

-- Legacy memorial attendance: SUM(passes_scanned) from 911dw.memorial_attendance
-- at the seeded memorial key_facility. The facility set is read from the seed,
-- not hardcoded, so the 2000 vs (1000,2000) decision is a data edit.
memorial_daily as (
    select
        f.date_key,
        sum(f.passes_scanned)                                              as mem_attendance
    from memorial_feed f
    inner join facility_group g
        on f.key_facility = g.key_facility
       and g.attendance_group = 'memorial'
    group by f.date_key
),

-- The two feeds are independent: a day can have scans and no memorial row, or
-- the reverse. Union the keys so neither side silently truncates the other.
date_spine as (
    select date_key from scan_daily
    union
    select date_key from memorial_daily
),

daily as (
    select
        sp.date_key,
        sd.mus_passes_scanned,
        sd.mem_passes_scanned_gateway,
        sd.uncounted_passes_scanned,
        md.mem_attendance
    from date_spine sp
    left join scan_daily     sd on sp.date_key = sd.date_key
    left join memorial_daily md on sp.date_key = md.date_key
),

flagged as (
    -- Legacy t_reporting_mus_attendance:
    --   CASE WHEN (DAYOFWEEK(key_date) IN (3) OR key_date = '20220615')
    --        AND SUM(v.passes_scanned) < 300 THEN 0 ELSE SUM(...) END
    -- Both halves of the OR and the threshold come from the seed. dayname() is
    -- used instead of dayofweek() so the rule does not depend on the Snowflake
    -- WEEK_START session parameter.
    select
        d.date_key,
        d.mus_passes_scanned,
        d.mem_passes_scanned_gateway,
        d.uncounted_passes_scanned,
        d.mem_attendance,
        count(r.rule_key) > 0                                              as is_museum_closed_day
    from daily d
    left join zeroing_rule r
        on (
               (r.rule_type = 'day_of_week'    and dayname(d.date_key) = r.day_of_week_name)
            or (r.rule_type = 'exception_date' and d.date_key          = r.exception_date)
           )
       and coalesce(d.mus_passes_scanned, 0) < r.min_threshold
    group by d.date_key, d.mus_passes_scanned, d.mem_passes_scanned_gateway,
             d.uncounted_passes_scanned, d.mem_attendance
)

select
    date_key,
    -- Museum: scanned passes at key_facility 1006 / 3000, zeroed on a closed day.
    case when is_museum_closed_day then 0 else mus_passes_scanned end       as mus_attendance,
    -- Carried alongside so the zeroing is auditable without re-deriving it.
    mus_passes_scanned                                                      as mus_passes_scanned,
    is_museum_closed_day,
    -- Memorial: SUM(passes_scanned) from 911dw.memorial_attendance at the seeded
    -- memorial facility. NULL only where the feed has no row for the day.
    mem_attendance,
    -- Monitor: scans that resolved to no attendance line (legacy else '0' bucket
    -- plus Gateway facility 12 -> key_facility 5000).
    uncounted_passes_scanned,
    -- Monitor: must stay NULL. A value here means a Gateway ACP now resolves to
    -- key_facility 2000 and memorial attendance has acquired a second writer.
    mem_passes_scanned_gateway
from flagged
