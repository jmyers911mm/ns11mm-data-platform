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
             and coalesce({{ va }}.itm_matrix_code, '') <> '%XGA'
            then 1
        else 0
    end
{%- endmacro %}