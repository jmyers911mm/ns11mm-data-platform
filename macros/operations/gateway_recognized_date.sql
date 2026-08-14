{#-
    gateway_recognized_date
    -------------------------------------------------------------------------
    Recreates the Galaxy "recognize basis" date logic used across the DPR
    tour/ticket line items. In the legacy .prpt the recognized key_date is:

        rItmRecognizeBasisID = 182 -> RMEvents.StartDateTime  (event date)
        rItmRecognizeBasisID = 185 -> jnlTickets.ticketDate
        rItmRecognizeBasisID = 349 -> dateadd(dd,14, jnlTickets.dateSold)

    All truncated to a date grain.

    DATA-QUALITY FIX (recognize-basis 182 + ticketdate):
      Diagnostics on the seed show the actual recognize-basis distribution is
      182 (92% of ticket qty), 187, 183, 185 -- and that basis-182 lines
      recognize on RMEvents.StartDateTime, but rme.start_at is NULL for ~95%
      of them (the rmevents seed / event-date is not resolving). Combined with
      jnltickets.ticketdate being ~95% unparseable, this produced a NULL
      recognized date for ~116k of 127k ticket units, which int_gateway__
      ticket_journal_lines then dropped via `where key_date is not null`.

      endoflifedate ("the actual visit date in Galaxy", already used as the
      substitute in the 1.4.0 stg_gateway__tickets fix) is populated for
      ~97.5% of basis-182 rows and equals the event/visit date for timed-entry
      admission, so every branch now coalesces to it:

        182 -> coalesce(rme.start_at, end_of_life_date, ticket_date)
        185 -> coalesce(ticket_date, end_of_life_date)
        349 -> sold_at + 14   (sold_at parses 100%)
        else (incl. 183/187) -> coalesce(ticket_date, end_of_life_date)

      FOLLOW-UP (not a blocker for volume): investigate why rme.start_at is
      NULL for basis-182 lines -- either the rmevents seed is a partial
      extract or the rme.event_id = jt.event_no join key mismatches. Restoring
      the true event date matters for TOUR products (ga_flag = 0), where the
      event date and visit date can differ. 183 and 187 are recognize bases
      not documented in the legacy CASE; the else fallback (visit date) is a
      safe default but should be confirmed against the Galaxy recognize-basis
      catalog.

    Usage:
        {{ gateway_recognized_date('va','jt','rme') }}

    where:
        va  = stg_gateway__vattribute alias (itm_recognize_basis_id)
        jt  = stg_gateway__jnltickets alias (ticket_date, end_of_life_date, sold_at)
        rme = stg_gateway__rmevents alias  (start_at)
-#}
{% macro gateway_recognized_date(va, jt, rme) -%}
    cast(
        case
            when try_cast({{ va }}.itm_recognize_basis_id as number) = 182
                then cast(coalesce({{ rme }}.start_at, {{ jt }}.end_of_life_date, {{ jt }}.ticket_date) as date)
            when try_cast({{ va }}.itm_recognize_basis_id as number) = 185
                then cast(coalesce({{ jt }}.ticket_date, {{ jt }}.end_of_life_date) as date)
            when try_cast({{ va }}.itm_recognize_basis_id as number) = 349
                then dateadd('day', 14, cast({{ jt }}.sold_at as date))
            else cast(coalesce({{ jt }}.ticket_date, {{ jt }}.end_of_life_date) as date)
        end
    as date)
{%- endmacro %}


{#-
    gateway_general_admission_flag
    -------------------------------------------------------------------------
    Recreates the GeneralAdmissionFlag CASE used to separate GA tickets from
    tour tickets. ga_flag = 1 means the line counts as general admission
    (attendance / GA revenue); ga_flag = 0 means it is a tour/other product.

    NOTE (disbursement_id): in the current seed extract disbursement_id is 0
    on every row, so the second branch (disbursement_id <> 0 ... GEN ADM) is
    never exercised and the tour-ticket-with-GA cohort is not separately
    credited. Confirm whether disbursement_id is genuinely always 0 in Galaxy
    or an extract artifact; if the latter, this branch (and any other
    disbursement-dependent logic) needs the corrected column before go-live.

    8.1.0 DEAD-CODE REMOVAL (the '%XGA' literal):
      This CASE previously carried

          and coalesce(va.itm_matrix_code, '') <> '%XGA'

      which is a LITERAL string comparison, not a pattern match, so it excluded
      only a matrix code whose value is the four characters %XGA. Galaxy matrix
      codes never contain '%', so the predicate was true for every row: dead.

      Column check (asked and answered): itm_matrix_code IS the right column.
      The legacy predicate reads `g.account_idno not like '%XGA%'`, and
      t_dim_galaxy_ticket_types builds dim_galaxy_items.account_idno as
      `ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo'` -- account_idno and
      itm_matrix_code are the same field under two names. So the column was
      never the problem.

      What IS wrong is the PLACEMENT, and legacy is wrong the same way:
      t_fact_museum_tickets_issued_fordate_new carries the identical dead
      literal inside its GeneralAdmissionFlag CASE. The live XGA exclusion
      lives one layer up, in the reporting query
      t_reporting_tickets_sold_issued_new, as a cohort filter on tickets
      sold/issued (`and g.account_idno not like '%XGA%'`) -- and it is NOT
      applied to ticket revenue (t_reporting_ticket_revenue_new has no XGA
      predicate at all).

      Turning the literal into `not like '%XGA%'` HERE would therefore diverge
      from legacy ga_flag classification rather than converge on it. The dead
      literal is removed; the real cohort exclusion is implemented where legacy
      implements it (int_dpr__admissions.tickets_sold) in release 8.6.0, under
      the ADR-005 gate, because it moves tickets sold.
-#}
{% macro gateway_general_admission_flag(va, jt, dd) -%}
    case
        when {{ jt }}.disbursement_id = 0
             and coalesce({{ va }}.itm_matrix_code, '') like 'GAD%'
            then 1
        when {{ jt }}.disbursement_id <> 0
             and (
                    coalesce({{ va }}.itm_matrix_code, '') like 'TOU%'
                 or coalesce({{ va }}.itm_matrix_code, '') like 'MGT%'
                 or coalesce({{ va }}.itm_matrix_code, '') like '%VTM%'
                 or coalesce({{ va }}.itm_matrix_code, '') like '%VTF%'
                 or coalesce({{ va }}.itm_matrix_code, '') like '%VTU%'
                 or coalesce({{ va }}.itm_matrix_code, '') like '%VTE%'
                 or coalesce({{ va }}.itm_matrix_code, '') like '%VTS%'
                 )
             and coalesce({{ dd }}.disbursement_name, 'GEN ADM') = 'GEN ADM'
            then 1
        else 0
    end
{%- endmacro %}