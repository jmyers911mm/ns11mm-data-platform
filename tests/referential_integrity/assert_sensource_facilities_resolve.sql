-- Test (referential_integrity): every facility present in the two visitor feeds
-- either resolves to a reporting facility in seed_sensource_facility_map or is
-- declared there as a known non-reporting sensor — and a declared non-reporting
-- sensor that is carrying volume is reported, not tolerated
-- Severity: warn — the feeds land as manually staged RAW tables with no landing
-- SLA and a sensor estate (Sensource ParentFacility 1000-1009, plus the Gateway
-- pass-scan writer) that is wider than the four mappings the live reports need.
-- An unmapped sensor is a signal to extend the crosswalk, not a reason to fail
-- the build. PROMOTE TO ERROR once the Sensource pull is orchestrated under
-- ADR-015 alerting AND the crosswalk has been confirmed complete against the
-- sensor estate with Gennady Zaritsky — after that, an unmapped facility means
-- a silently dropped denominator.
--
-- 8.4.0 rewrite. The previous version returned only facilities with no seed row
-- at all, and returned them identically whether they carried 7,948 entries a day
-- or none. It therefore could not distinguish the finding from the noise, and a
-- zero-volume sensor (1009) raised nothing anyone would act on. This version:
--   * covers BOTH feeds — stg_sensource__visitors and stg_memorial__attendance —
--     because the crosswalk now spans three source systems;
--   * reports declared-but-non-reporting sensors (is_reporting = FALSE: 1008,
--     1009) alongside genuinely unmapped ones, so declaring a sensor in the seed
--     does not make it disappear from review;
--   * carries a `finding` column so the reason a row is here is explicit;
--   * asserts leg integrity — a facility whose seed row belongs to a DIFFERENT
--     source_system than the feed it turned up in means a writer changed.

{{ config(severity='warn') }}

with visitor_feed as (
    select
        'sensource_visitors'            as feed,
        key_facility,
        business_date,
        num_entry,
        num_exit,
        passes_scanned
    from {{ ref('stg_sensource__visitors') }}
),

memorial_feed as (
    select
        'memorial_attendance'           as feed,
        key_facility,
        business_date,
        cast(null as number(18,0))      as num_entry,
        cast(null as number(18,0))      as num_exit,
        passes_scanned
    from {{ ref('stg_memorial__attendance') }}
),

feeds as (
    select * from visitor_feed
    union all
    select * from memorial_feed
),

map as (
    select
        sensource_facility,
        source_system,
        is_reporting
    from {{ ref('seed_sensource_facility_map') }}
),

-- The source_system each feed is allowed to resolve against. fact_visitors
-- carries both the Sensource API leg and the Gateway pass-scan leg;
-- memorial_attendance carries only the memorial feed.
by_facility as (
    select
        f.feed,
        f.key_facility,
        m.sensource_facility,
        m.source_system,
        m.is_reporting,
        count(*)                        as feed_rows,
        min(f.business_date)            as first_seen,
        max(f.business_date)            as last_seen,
        sum(f.num_entry)                as unmapped_entries,
        sum(f.num_exit)                 as unmapped_exits,
        sum(f.passes_scanned)           as unmapped_passes
    from feeds f
    left join map m
        on f.key_facility = m.sensource_facility
    group by 1, 2, 3, 4, 5
),

findings as (
    select
        case
            when sensource_facility is null
                then 'NO SEED ROW — facility is in the feed and in no crosswalk row'
            when not is_reporting
                then 'DECLARED NON-REPORTING — seeded with no reporting facility; dropped from every report'
            when feed = 'sensource_visitors' and source_system not in ('sensource', 'gateway_scan')
                then 'WRONG LEG — seed row belongs to another source_system; a writer has changed'
            when feed = 'memorial_attendance' and source_system <> 'memorial_feed'
                then 'WRONG LEG — seed row belongs to another source_system; a writer has changed'
        end                             as finding,
        feed,
        key_facility,
        source_system,
        is_reporting,
        feed_rows,
        first_seen,
        last_seen,
        coalesce(unmapped_entries, 0)   as unmapped_entries,
        coalesce(unmapped_exits, 0)     as unmapped_exits,
        coalesce(unmapped_passes, 0)    as unmapped_passes
    from by_facility
)

select
    finding,
    feed,
    key_facility,
    source_system,
    is_reporting,
    feed_rows,
    first_seen,
    last_seen,
    unmapped_entries,
    unmapped_exits,
    unmapped_passes,
    -- Size of the gap, so a busy unmapped door (1008) reads differently from a
    -- silent one (1009) without anyone having to run a second query.
    unmapped_entries + unmapped_exits + unmapped_passes                 as unmapped_total,
    case when unmapped_entries + unmapped_exits + unmapped_passes > 0
         then 'MATERIAL' else 'ZERO VOLUME' end                        as volume_class
from findings
where finding is not null
order by unmapped_total desc, key_facility
