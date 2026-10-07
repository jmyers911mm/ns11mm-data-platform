# 8.3.0: Retail Profit Correctness (return cost, ticket header)

- **Date:** 2026-08-12
- **Version:** 8.3.0

Ships on top of 8.2.0 — the `int_counterpoint__retail_lines` shipped here is the cumulative
8.2.0 + 8.3.0 state; do not apply the 8.2.0 copy after it. Three defects, all in the same
chain: the retail line model never joined a ticket header, so unposted and non-ticket
documents were being reported and costed; cost was taken from sale lines only, so a return
handed back the revenue but kept the cost; and customer counts were a grouped
`count(distinct doc_id)` off the sales scope, on the wrong date column, ignoring every
`doc_id` semi-join legacy uses.

## Added

- **`return_cost`, `net_cost` and a carried `ticket_date`** on
  `int_counterpoint__retail_lines`.
- **`assert_retail_gross_profit_nets_returns`** — the reconciliation test that fails on ship
  if the netting is not carried through to the consumers.
- **`dbt_project.yml` version 8.2.0 → 8.3.0.**

## Changed

- **`int_counterpoint__retail_lines`** gains the `pstkthist` header join with `TKT_TYP = 'T'`
  and the `LIN_TYP <> 'U'` line filter, exactly as `t_fact_cogs` gates every branch.
  `stg_counterpoint__pstkthist`, `stg_counterpoint__vitkthist` and
  `stg_counterpoint__vitkthistlin` were staged and read by **nothing** before this.
- **`int_retail__customers`** rewritten as the eleven legacy cohorts, counting on
  `TICKET.TKT_DT` (the header ticket date) rather than `LINE.BUS_DAT`, with the `doc_id`
  semi-joins legacy uses. Memorial Carts is stores 11, 12 and 13 — not 14 — and excludes any
  document containing `200933`, `201229`, `201114` or `201197` from 2023-09-04. MAG, MUS AG,
  MTG and Membership use the **inverse** semi-join: documents that *do* contain the carve-out
  SKU.
- **`int_retail__performance`** — `net_profit` and `cost_of_goods` move from `sale_cost` to
  `net_cost`. Not on the original deliverable list but required: without it the new column
  exists, nothing changes, and the new test fails on ship.
- **`int_dpr__retail`** — the four cost lines (`mus_store_cost`, `mem_cart_cost`,
  `cafe1_cost`, `musag_cost`) move to `net_cost`. Also not on the original list, also
  required.

## Numbers that move

- **Gross profit DROPS on any day with a return. That is the headline.** `t_fact_cogs` sums
  `LINE.EXT_COST` over **all** surviving lines in every branch — there is no
  `CASE LIN_TYP WHEN 'S'` anywhere in that file — while the platform had
  `case when l.line_type = 'S' then l.ext_cost else 0 end`. Revenue netted the return; cost
  did not. **Profit was overstated by the cost of every returned item.** Affected and all
  moving down: `net_profit` and `cost_of_goods` on `int_retail__performance` and
  `fct_retail_performance`, `net_profit` on `fct_retail_daily`, `mus_store_gross_profit` /
  `retail_carts_gross_profit` / `cafe1_all_profit` / `musag_profit` on `int_dpr__retail`, and
  everything downstream of those four on `fct_daily_performance` including
  `audio_tour_headset`. If the number is material to a published month, that is an ADR-005
  conversation with Gennady Zaritsky **before** the build lands, not after.
- **Row count and most measures fall on the header gate.** Documents whose `TKT_TYP` is not
  `'T'` (quotes, orders, holds) and `'U'` lines leave; sales, cost, units and transaction
  counts fall by whatever those carried. A drop far larger than a percent or two means the
  `TKT_TYP` values in the staged extract are not what legacy saw — check before shipping,
  because the inner join is unforgiving.
- **Customer counts: 1020 falls** (store 14 removed, carve-out documents excluded); **1001 and
  1002 are counted for the first time**; **1040, 1060, 1070 and 1080 are replaced by their
  semi-join cohorts** rather than being an artefact of the item→facility mapping; and **every
  facility shifts by a day at the margin** on `TKT_DT` versus `BUS_DAT`.
  `fct_retail_daily.transactions` and every ratio built on it — conversion rate, average sale,
  per-cap donations — move accordingly.

## Findings recorded in the caveats tables (no code change this release)

- **The return sign convention is still an unconfirmed `CONFIRM`, standing since 7.9.0.** The
  direction argument above depends on CounterPoint `'R'` lines landing with **negative**
  `ext_cost`. Query (B) in NOTES proves it on live data and must be run first: if `'R'` cost
  lands positive, the netting flips, profit moves the other way, and the sign must change in
  `int_counterpoint__retail_lines` and nowhere else.
- **`stg_counterpoint__pstkthist` aliases `TKT_TYP` as `is_return`**, which is a misnomer — it
  is a type code, not a boolean. ADR-001 keeps staging rename-only, so it is read as-is; fix
  the alias in a follow-up.
- **Legacy reads the `VI_` reporting views and joins on `DOC_ID` *and* `BUS_DAT`;** this model
  joins the posted header on `doc_id` alone, which is the header PK at that grain. Moving to
  the `VI_` views means moving **both** sides.
- **The Museum Store cohort's operator precedence is almost certainly a legacy bug, and it is
  what produced the certified series.** `WHERE A OR (B AND C) AND TKT_DT > '20170423'` binds
  `AND` tighter than `OR`, so stores 8/9/10 have **no start date** and only the store-14
  carve-in is bounded. Reproduced.
- **The Membership cohort starts 2023-11-29 in `t_fact_num_tickets` and 2024-01-21 in
  `t_fact_cogs`**, so 1080 carries roughly seven weeks of transaction counts with no sales.
  Pick one date before publishing a 1080 per-transaction ratio.
