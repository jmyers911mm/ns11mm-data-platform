-- Test (referential_integrity): every seeded Earned Income line produces rows, and every produced line is seeded
-- Severity: warn — the schema.yml relationships test already errors on a line
-- code in the report that the seed does not catalog. This test covers the
-- OPPOSITE and more dangerous direction: a line the seed promises and the report
-- never emits. The symptom of that is a printed workbook row that silently
-- disappears rather than rendering blank, which on a variance report reads as
-- "this line had no activity" rather than "this line is missing".
--
-- It is warn rather than error because it fires legitimately on a partial
-- dataset (a dev environment loaded with a short date window). PROMOTE TO ERROR
-- once 8.11.0 has run a full-history build in production and every seeded line
-- has been confirmed to emit.
--
-- Stub lines are expected to APPEAR here with NULL amounts, not to vanish: they
-- are emitted with a typed-NULL measure, which is the ADR-021 placeholder rule.
-- A Stub line missing entirely is a real failure and this test catches it.
--
-- The third branch is the one that matters most on this report: an 'Available'
-- line that emits rows but never a value is mislabelled, and the layout is then
-- promising the CFO a number the platform does not actually produce.

{{ config(severity='warn') }}

with seeded as (
    select
        line_item_code,
        section,
        availability,
        value_type
    from {{ ref('earned_income_line_items') }}
),

emitted as (
    select
        line_item_code,
        count(*)                                        as row_count,
        count(amount)                                   as non_null_amounts,
        count(numerator)                                as non_null_numerators,
        count(budget_amount)                            as non_null_budget_amounts,
        count(budget_numerator)                         as non_null_budget_numerators
    from {{ ref('rpt_earned_income_variance_report_long') }}
    group by 1
),

missing_from_report as (
    select
        'seeded_line_emits_no_rows'                     as failure,
        s.line_item_code,
        s.section,
        s.availability,
        cast(0 as number(38, 0))                        as row_count
    from seeded s
    left join emitted e on s.line_item_code = e.line_item_code
    where e.line_item_code is null
),

missing_from_seed as (
    select
        'emitted_line_is_not_seeded'                    as failure,
        e.line_item_code,
        cast(null as varchar)                           as section,
        cast(null as varchar)                           as availability,
        e.row_count
    from emitted e
    left join seeded s on e.line_item_code = s.line_item_code
    where s.line_item_code is null
),

available_but_empty as (
    select
        'available_line_has_no_values'                  as failure,
        s.line_item_code,
        s.section,
        s.availability,
        e.row_count
    from seeded s
    inner join emitted e on s.line_item_code = e.line_item_code
    where s.availability = 'Available'
      and e.non_null_amounts = 0
      and e.non_null_numerators = 0
),

-- A Stub line must render as present-and-blank on BOTH scenarios. A Stub line
-- that has acquired a value means a feed landed and the layout was not updated
-- (harmless but stale), or a zero-fill crept in (not harmless).
stub_but_populated as (
    select
        'stub_line_has_a_value'                         as failure,
        s.line_item_code,
        s.section,
        s.availability,
        e.non_null_amounts + e.non_null_budget_amounts  as row_count
    from seeded s
    inner join emitted e on s.line_item_code = e.line_item_code
    where s.availability = 'Stub'
      and (e.non_null_amounts > 0 or e.non_null_budget_amounts > 0)
),

-- Every ratio line must carry components on at least one scenario, and no
-- additive line may carry components. This is the ADR-021 ratio rule expressed
-- as a shape check on the serving model.
ratio_shape as (
    select
        'ratio_line_carries_no_components'              as failure,
        s.line_item_code,
        s.section,
        s.availability,
        e.row_count
    from seeded s
    inner join emitted e on s.line_item_code = e.line_item_code
    where s.value_type = 'ratio'
      and e.non_null_numerators = 0
      and e.non_null_budget_numerators = 0

    union all

    select
        'additive_line_carries_ratio_components',
        s.line_item_code,
        s.section,
        s.availability,
        e.non_null_numerators
    from seeded s
    inner join emitted e on s.line_item_code = e.line_item_code
    where s.value_type = 'additive'
      and (e.non_null_numerators > 0 or e.non_null_budget_numerators > 0)
)

select * from missing_from_report
union all
select * from missing_from_seed
union all
select * from available_but_empty
union all
select * from stub_but_populated
union all
select * from ratio_shape
