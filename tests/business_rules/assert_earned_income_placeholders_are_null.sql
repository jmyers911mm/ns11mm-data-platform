-- Test (business_rule): the nine unstaged Earned Income cohorts are typed NULL, never zero
-- Severity: error — every column checked here is an ADR-021 placeholder: a
-- legacy cohort whose source fact is not staged. NULL means "the platform has no
-- feed for this". Zero means "the cohort was empty that day". On this report the
-- difference is money: nine of these cohorts sit inside Ticket Revenue, Tickets
-- or CityPASS Revenue, and a zero-filled placeholder would make a Partial line
-- look Available and would make the CFO's variance look explained when it is not.
--
-- This is the cheapest possible guard against the single most likely regression
-- in this release: somebody adds coalesce(..., 0) to make a not_null test pass,
-- or folds a placeholder into a roll-up.
--
-- It also asserts the second half of the rule: the placeholders must NOT be
-- inside the roll-ups. tickets, ticket_revenue, citypass_tickets and
-- citypass_revenue are sums of the cohorts that HAVE a feed; if a NULL cohort
-- were added into one of them the roll-up itself would go NULL, so a NULL
-- roll-up is a failure too.
--
-- Delete a branch here in the same release that lands the corresponding feed.

with f as (
    select * from {{ ref('fct_earned_income') }}
),

zero_filled as (
    select
        count_if(tickets_scanchange_ga      is not null)  as tickets_scanchange_ga,
        count_if(tickets_bulk_scan          is not null)  as tickets_bulk_scan,
        count_if(child_evg_tickets          is not null)  as child_evg_tickets,
        count_if(ticket_revenue_scanchange  is not null)  as ticket_revenue_scanchange,
        count_if(ticket_revenue_nyp_add     is not null)  as ticket_revenue_nyp_add,
        count_if(ticket_revenue_bulk_add    is not null)  as ticket_revenue_bulk_add,
        count_if(ticket_revenue_bulk_scan   is not null)  as ticket_revenue_bulk_scan,
        count_if(citypass_tickets_scanchange is not null) as citypass_tickets_scanchange,
        count_if(citypass_revenue_scanchange is not null) as citypass_revenue_scanchange,
        count_if(tickets          is null)                as tickets_rollup_null,
        count_if(ticket_revenue   is null)                as ticket_revenue_rollup_null,
        count_if(citypass_tickets is null)                as citypass_tickets_rollup_null,
        count_if(citypass_revenue is null)                as citypass_revenue_rollup_null
    from f
)

select 'placeholder_is_populated'  as failure, 'tickets_scanchange_ga'       as column_name, tickets_scanchange_ga       as bad_rows from zero_filled where tickets_scanchange_ga       > 0
union all
select 'placeholder_is_populated', 'tickets_bulk_scan',           tickets_bulk_scan           from zero_filled where tickets_bulk_scan           > 0
union all
select 'placeholder_is_populated', 'child_evg_tickets',           child_evg_tickets           from zero_filled where child_evg_tickets           > 0
union all
select 'placeholder_is_populated', 'ticket_revenue_scanchange',   ticket_revenue_scanchange   from zero_filled where ticket_revenue_scanchange   > 0
union all
select 'placeholder_is_populated', 'ticket_revenue_nyp_add',      ticket_revenue_nyp_add      from zero_filled where ticket_revenue_nyp_add      > 0
union all
select 'placeholder_is_populated', 'ticket_revenue_bulk_add',     ticket_revenue_bulk_add     from zero_filled where ticket_revenue_bulk_add     > 0
union all
select 'placeholder_is_populated', 'ticket_revenue_bulk_scan',    ticket_revenue_bulk_scan    from zero_filled where ticket_revenue_bulk_scan    > 0
union all
select 'placeholder_is_populated', 'citypass_tickets_scanchange', citypass_tickets_scanchange from zero_filled where citypass_tickets_scanchange > 0
union all
select 'placeholder_is_populated', 'citypass_revenue_scanchange', citypass_revenue_scanchange from zero_filled where citypass_revenue_scanchange > 0
union all
select 'rollup_absorbed_a_null_placeholder', 'tickets',          tickets_rollup_null          from zero_filled where tickets_rollup_null          > 0
union all
select 'rollup_absorbed_a_null_placeholder', 'ticket_revenue',   ticket_revenue_rollup_null   from zero_filled where ticket_revenue_rollup_null   > 0
union all
select 'rollup_absorbed_a_null_placeholder', 'citypass_tickets', citypass_tickets_rollup_null from zero_filled where citypass_tickets_rollup_null > 0
union all
select 'rollup_absorbed_a_null_placeholder', 'citypass_revenue', citypass_revenue_rollup_null from zero_filled where citypass_revenue_rollup_null > 0
