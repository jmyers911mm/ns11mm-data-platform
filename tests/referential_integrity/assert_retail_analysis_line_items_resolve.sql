-- Test (referential_integrity): every seeded Retail Analysis line produces rows, and every produced line is seeded
-- Severity: warn — the schema.yml relationships test already errors on a line
-- code in the report that the seed does not catalog. This test covers the
-- OPPOSITE and more dangerous direction: a line the seed promises and the
-- report never emits. That happens when a facility_group has no rows at all in
-- fct_retail_analysis, and the symptom is a printed workbook column that
-- silently disappears rather than rendering blank.
--
-- It is warn rather than error because it fires legitimately on a partial
-- dataset (a dev environment loaded with a short date window may have no
-- Preview Site / Vesey or no E-Commerce rows). PROMOTE TO ERROR once 8.10.0
-- has run a full-history build in production and every seeded line has been
-- confirmed to emit — after that, a vanished line means a broken facility_group
-- predicate in rpt_retail_analysis_report_long.
--
-- Stub lines are expected to APPEAR here with NULL amounts, not to vanish: they
-- are emitted from their facility's own rows with a typed-NULL measure, which
-- is the ADR-021 placeholder rule. A Stub line missing entirely is a real
-- failure and this test catches it.

{{ config(severity='warn') }}

with seeded as (
    select
        line_item_code,
        section,
        availability,
        facility_group
    from {{ ref('retail_analysis_line_items') }}
),

emitted as (
    select
        line_item_code,
        count(*)                                as row_count,
        count(amount)                           as non_null_amounts,
        count(numerator)                        as non_null_numerators
    from {{ ref('rpt_retail_analysis_report_long') }}
    group by 1
),

missing_from_report as (
    select
        'seeded_line_emits_no_rows'             as failure,
        s.line_item_code,
        s.section,
        s.availability,
        s.facility_group,
        cast(0 as number(38, 0))                as row_count
    from seeded s
    left join emitted e on s.line_item_code = e.line_item_code
    where e.line_item_code is null
),

missing_from_seed as (
    select
        'emitted_line_is_not_seeded'            as failure,
        e.line_item_code,
        cast(null as varchar)                   as section,
        cast(null as varchar)                   as availability,
        cast(null as varchar)                   as facility_group,
        e.row_count
    from emitted e
    left join seeded s on e.line_item_code = s.line_item_code
    where s.line_item_code is null
),

-- An 'Available' line that emits rows but never a value is mislabelled: the
-- layout promises a number the platform does not actually produce.
available_but_empty as (
    select
        'available_line_has_no_values'          as failure,
        s.line_item_code,
        s.section,
        s.availability,
        s.facility_group,
        e.row_count
    from seeded s
    inner join emitted e on s.line_item_code = e.line_item_code
    where s.availability = 'Available'
      and e.non_null_amounts = 0
      and e.non_null_numerators = 0
)

select * from missing_from_report
union all
select * from missing_from_seed
union all
select * from available_but_empty
