{#-
    gateway_recognized_date
    -------------------------------------------------------------------------
    Recreates the Galaxy "recognize basis" date logic used across the DPR
    tour/ticket line items. In the legacy .prpt the recognized key_date is:

        rItmRecognizeBasisID = 182 -> RMEvents.StartDateTime  (event date)
        rItmRecognizeBasisID = 185 -> jnlTickets.ticketDate
        rItmRecognizeBasisID = 349 -> dateadd(dd,14, jnlTickets.dateSold)

    All truncated to a date grain. This macro takes the aliases of the
    joined staged relations and returns a DATE expression.

    Usage:
        {{ gateway_recognized_date('va','jt','rme') }}

    where:
        va  = stg_gateway__vattribute alias (itm_recognize_basis_id)
        jt  = stg_gateway__jnltickets alias (ticket_date, sold_at)
        rme = stg_gateway__rmevents alias  (start_at)
-#}
{% macro gateway_recognized_date(va, jt, rme) -%}
    cast(
        case
            when {{ va }}.itm_recognize_basis_id = 182 then cast({{ rme }}.start_at as date)
            when {{ va }}.itm_recognize_basis_id = 185 then cast({{ jt }}.ticket_date as date)
            when {{ va }}.itm_recognize_basis_id = 349 then dateadd('day', 14, cast({{ jt }}.sold_at as date))
            else cast({{ jt }}.ticket_date as date)
        end
    as date)
{%- endmacro %}


{#-
    gateway_general_admission_flag
    -------------------------------------------------------------------------
    Recreates the GeneralAdmissionFlag CASE used to separate GA tickets from
    tour tickets. ga_flag = 1 means the line counts as general admission
    (attendance / GA revenue); ga_flag = 0 means it is a tour/other product.
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
