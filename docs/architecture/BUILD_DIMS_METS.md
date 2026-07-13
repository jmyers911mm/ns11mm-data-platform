# Building Reports, Semantic Views, and Metrics

**Audience:** Data platform developers (Kalea, Phinn, Diana, contributors)
**Governs:** any PR that adds or changes an `rpt_` model, a semantic view, or a metric
**Authority:** ADR-005 (Metric Gate), ADR-009 (Metric Definition Ownership). This guide is the how-to; the ADRs are the why. If they conflict, the ADRs win.

---

## The one rule everything else follows from

A metric is **defined once** and **served many times.**

- Defining a metric means encoding its population and its business rule: which rows count, what gets measured, net or gross, which date basis. This happens in exactly one place, upstream in dbt.
- Serving a metric means aggregating an already-defined measure by some grain and slice. This happens in as many semantic views and `rpt_` tables as you need.

Everything below is the mechanics of keeping those two things separate.

---

## Where each layer is allowed to do work

| Layer | Allowed to do | Never does |
|---|---|---|
| `fct_` / `dim_` (fact grain) | Define the metric: governed measure column or flag, tested once | — |
| Semantic view | Expose: aggregate the governed column by grain and dimension | Define a metric, contain `SUM(CASE...)` that encodes a population, add a filter that changes which rows count |
| `rpt_` model | Project: materialize already-defined metrics for cache, shape, or snapshot | Re-derive a metric, add new aggregation math, select from another `rpt_` |
| Power BI | Render only (ADR-004) | Any logic |

If you find yourself writing a `SUM(CASE WHEN ...)` that decides *which rows are a ticket* anywhere except the fact model, stop. That logic belongs upstream.

---

## Before you build: classify every metric your report needs

For each metric the new report requires, answer one question: **does this metric already exist as a certified definition?**

### It already exists, unchanged
This is the common case and the easy one. You are a new **consumer** of an existing definition.
- Reference the same upstream governed measure. If the metric is a rate, reference the same certified numerator and denominator pairing, not a re-chosen one.
- Do **not** pass through the ADR-005 gate. The gate fires on new definitions, not new consumers.
- Your semantic view or `rpt_` exposes the existing measure at your grain: an aggregation for an additive measure, or `SUM(numerator) / SUM(denominator)` computed at your grain for a rate.

### It looks like an existing metric but differs (a "cousin")
Example: the DPR's `tickets_sold` is net of comps and on recognized-date basis. Your operational attendance report wants a gross count on transaction-date. These look alike. They are not the same metric.
- Give it a **distinct name.** Never reuse the certified name for a different population.
- It is a **new definition.** It passes through the ADR-005 gate.
- Record the distinction (a one-line note on why it is a cousin, not the original) in the PR.

**"Almost the same" is never a valid answer.** If you cannot say cleanly "same" or "cousin," you do not yet understand the metric well enough to build it. Resolve that first. A cousin shipped under the original's name, with the difference buried in a filter, is the single worst outcome in this whole process: it looks reconciled and is wrong.

### It is genuinely new
- It passes through the ADR-005 gate: definition precedes build.
- It is defined once, upstream, at or below the fact grain.
- Then it is exposed by your view or `rpt_`.

---

## Decision tree: does this report need an `rpt_` table at all?

```
Does the report need a metric not yet defined?
   YES -> define it upstream first (ADR-005 gate). Then continue.
   NO  -> continue.

Can Power BI or Cortex serve this directly off a semantic view?
   YES -> stop. No rpt_ table. This is the preferred outcome:
          zero drift risk by construction.
   NO  -> continue.

Do you need a materialization for a nameable reason?
   (hot dashboard perf, a specific wide shape, a pinned snapshot)
   YES -> build an rpt_ as a PROJECTION of already-defined metrics.
          No new math. Add reconciliation tests. See below.
   NO  -> you probably do not need the table. Serve off the view.
```

The test for whether an `rpt_` is justified: **if you deleted it, could you reproduce the same numbers through the semantic view?**
- Yes, and performance is fine -> you did not need the table.
- Yes, but it is too slow -> the table is a valid performance materialization. Keep it.
- No -> logic is hiding in the table that belongs upstream. That is the anti-pattern. Move the logic up.

---

## Building a semantic view

### Source of truth: `dpr.yaml` → `create_dpr_semantic_view.sql`

Metric definitions live in **one place**: `semantic_models/dpr.yaml`. The SQL DDL that deploys the semantic view (`semantic_models/create_dpr_semantic_view.sql`) is a **generated artifact** — never hand-edited.

```
dpr.yaml  ──→  generate_dpr_semantic_view.py  ──→  create_dpr_semantic_view.sql
(edit here)       (transformer script)              (deploy this, never edit)
```

**How they stay in sync:**

1. A pre-commit hook (`.githooks/pre-commit`) detects staged changes to `dpr.yaml` or `generate_dpr_semantic_view.py`.
2. It re-runs the generator and auto-stages the updated SQL.
3. The commit therefore always contains a SQL file that matches the YAML.

To verify manually: `python scripts/generate_dpr_semantic_view.py --check` exits non-zero if the SQL has drifted.

**Non-additive ratios (e.g. `avg_ticket_price`):**

Ratios are defined once in the YAML as ratio-of-sums expressions:

```yaml
- name: avg_ticket_price
  expr: SUM(TOTAL_ADMISSION_REVENUE) / NULLIF(SUM(TICKETS_SOLD), 0)
```

The generator emits this verbatim into the semantic view DDL. Because the expression uses `SUM(numerator) / SUM(denominator)`, Snowflake recomputes it at whatever grain the query requests — it is never pre-aggregated and re-averaged.

**Future-proofing for multiple views:** The generator is structured so that additional semantic views (at different grains or for different audiences) can inherit ratio definitions from the same YAML without duplicating the formula. Today it produces one view; adding more requires only extending the generator's output targets while the metric definitions remain in a single place.

### Drift detection: `assert_rpt_avg_ticket_price.sql`

The reconciliation test `tests/reconciliation/assert_rpt_avg_ticket_price.sql` catches formula drift between the `rpt_` materialization and the governed fact:

```sql
-- Compares rpt_daily_performance_report.avg_ticket_price against
-- fct_daily_performance.total_admission_revenue / tickets_sold at day grain.
-- Fails if any day diverges by more than $0.01.
```

This test fires in CI on every build. If the `rpt_` table's formula ever diverges from the governed upstream components — because someone edited the report model's SQL rather than the YAML — the build goes red. The semantic view itself cannot drift (it is generated from the YAML), so the test specifically guards the `rpt_` layer where hand-edits are still possible.

### General rules for semantic views

1. Every metric in the view resolves to a governed upstream measure. Confirm each one is "same" or a named "cousin" per the classification above.
2. Keep it thin. A metric declaration should look like an aggregation over a governed column (`SUM(ticket_count)`, `COUNT(*)` over a governed population), not a re-encoding of the population.
3. Vary only grain and dimension across views. Two views summing the same governed column may roll up by month here and by campaign there. They may not each decide what a ticket is.
4. If you are hand-authoring the view and we already have a canonical metric catalogue, generate from the catalogue instead. Hand-authoring stops being safe past ~3 views.

**Smell test:** if your semantic view contains derivation logic (a CASE that filters a population, a join that changes the counted set), it is doing the fact model's job. Push it down.

---

## Building an `rpt_` model

1. Select from `fct_` / `dim_`, and from a semantic view where that guarantees inheritance of the definition. Where the platform supports selecting *through* the semantic view, prefer it: the table then physically cannot diverge from the definition (`fct -> semantic view -> rpt_`).
2. Add no aggregation that redefines a metric and no filter that changes which rows a certified metric counts. Reshaping, pivoting, pre-joining, and pre-aggregating an already-defined measure are all fine. Redefining is not.
3. Never select from another `rpt_`. If you need something another report computed, get it from the shared upstream source both reports draw on, not from the other report.
4. Add reconciliation tests (next section).

---

## Reconciliation tests (required for shared metrics)

For every metric your artifact shares with another artifact, assert in CI that they reconcile to the same upstream measure at a common grain.

- Minimum: `rpt_<domain>.<metric>` equals the semantic view's `<metric>` for the same grain and filters.
- Where multiple views share a metric: all exposures reconcile to the shared upstream measure at a common grain.
- When every exposure references the same governed fact column, this test is nearly structural: passing it means nobody slipped in a redefining filter.

**Non-additive metrics (rates, ratios, averages) reconcile differently.** A rate does not reconcile across grains and must never be asserted to. Reconcile it in two parts: (1) its additive components (numerator, denominator) reconcile across grains as ordinary sum checks, and (2) the rate itself reconciles only at a *common* grain, where every exposure must return the same `SUM(numerator) / SUM(denominator)`. Storing a pre-computed rate and re-aggregating it is a build error the reconciliation test is meant to catch, so test the components and the formula, not the rate value across grains.

These live alongside the existing test assertions. A drift becomes a red build, not a surprise in a stakeholder meeting.

---

## PR review checklist

A PR touching an `rpt_` model or semantic view is not mergeable until:

- [ ] Every metric is classified **same** (reuse, no gate) or **cousin** (distinct name, gate). No "almost the same."
- [ ] No semantic view or `rpt_` re-derives a metric (no population-encoding `CASE`, no counting filter).
- [ ] No `rpt_` selects from another `rpt_`.
- [ ] Only genuinely new definitions passed through the ADR-005 gate; reuse did not.
- [ ] Reconciliation tests exist for every shared metric and pass.
- [ ] Shared metric logic lives at or below the fact grain, not in the view or table.

Reviewer is Jeremy (exclusive merger to dev/main). CODEOWNERS co-owner: Kalea.

---

## Worked example: DPR `average_ticket_price` reused by an Attendance report

A rate is the case where "define once, serve many" gets genuinely subtle, so this example uses one deliberately. The trap that a sum or count never exposes is that **a rate is non-additive**: you cannot sum it, and you cannot average it across grains. A day's average ticket price does not average to the month's. That single fact drives everything below.

**Situation.** The DPR certifies `average_ticket_price` (yield): `ticket_revenue / tickets_sold`, both on recognized-date basis. A new Attendance semantic view wants the same yield metric, rolled up by day.

**The definition is a pair of measures plus a formula, not a stored number.** `average_ticket_price` is not a column sitting on any row. It is defined as the ratio of two already-governed measures:
- numerator: `ticket_revenue` (governed on `fct_ticket_sales`)
- denominator: `tickets_sold` (governed on `fct_ticket_sales`)
- rule: `SUM(ticket_revenue) / SUM(tickets_sold)`, computed **at the grain being viewed**, marked non-additive.

What is certified once is *which numerator over which denominator*. Both components already exist, so no new governed column is created upstream. The certified thing that is new is the pairing.

**Classify.** Attendance wants the identical pairing and rule, at a different grain. That is the **same** metric, different grain. No new definition, no gate. It is pure exposure.

**Build.**
- Nothing new upstream. `ticket_revenue` and `tickets_sold` are already governed measures.
- The Attendance view exposes `average_ticket_price` as `SUM(ticket_revenue) / SUM(tickets_sold)`, sliced by day. It is still a thin view: it does not choose its own numerator or denominator, does not filter the population, and does not invent a new component. It renders the certified pairing at its grain.
- No `rpt_` is needed unless a dashboard is slow. If one is built, it stores the **components** (`ticket_revenue`, `tickets_sold`) pre-aggregated at a base grain and computes the ratio on read. It must not store the *rate itself* and let a downstream report re-aggregate it. Storing a per-day rate and averaging it to a month is the classic non-additive error.

**Test.** This is where a rate differs from a count. You do **not** assert that the daily rate equals the monthly rate; it should not, and asserting it would be wrong. Reconciliation for a rate is two checks:
1. **Components reconcile.** Attendance `ticket_revenue` and `tickets_sold` reconcile to the same governed measures the DPR uses, at a common grain (these are additive, so this is the ordinary sum check).
2. **Formula matches.** Both views compute the rate as `SUM(numerator) / SUM(denominator)` over those governed components, at the grain requested. At an identical grain and slice, the two views return an identical rate. If they diverge at equal grain, the build goes red.

So you reconcile the additive components across grains, and you reconcile the rate only at a common grain. Never assert a rate reconciles across grains.

**Counter-example (the trap).** Attendance actually wants yield computed on *gross bookings including comps* in the denominator, while the DPR excludes comps. Same-looking rate, different denominator population. That is a **cousin**, not `average_ticket_price`. It gets a distinct name (for example `average_gross_yield`), its own certified pairing, and the ADR-005 gate. It must never ship as `average_ticket_price` with the denominator quietly swapped inside the view, because the two would look reconciled at first glance and disagree everywhere.

### Flow: where the rate is defined when two views sit at different grains

Suppose the two consumers need the rate at genuinely different grains: the DPR wants `average_ticket_price` per **day**, while a Channel Performance view wants it per **sales channel** (window, online, group sales, member). These grains are not even nested, one is a date and the other is a channel.

**Different grains do not move the definition.** Grain is a property of exposure, not of definition. The rate is still defined exactly once, upstream, and both views inherit it. What differing grains actually require is this: the governed components must be carried at a grain **fine enough that every consumer grain can roll up from it.** The atomic fact grain (one row per ticket line, carrying both `ticket_revenue` and `tickets_sold`) is that floor, which is precisely why the definition lives there and not at either view's grain. A day view rolls the atomic rows up by date; a channel view rolls the same atomic rows up by channel. Neither view's grain could serve the other, but the atomic grain serves both.

The non-additivity of the rate makes this non-negotiable. You cannot pre-compute `average_ticket_price` at the day grain and expect the channel view to derive its number from it, and vice versa. Only the additive components survive being carried at the fine grain; the ratio is recomputed at each view's grain. So more divergent grains make the single upstream definition **more** important, not less, since materializing the rate at any one grain would strand every other grain.

```
                    DEFINED ONCE  (upstream in dbt)
   +-----------------------------------------------------------+
   |                                                           |
   |   fct_ticket_sales                                        |
   |   ATOMIC grain: one row per ticket line                   |
   |   (fine enough that ANY consumer grain rolls up from it)  |
   |            |                                              |
   |            v                                              |
   |   Governed components: ticket_revenue, tickets_sold       |
   |   additive, tested once, carried at the atomic grain      |
   |            |                                              |
   |            v                                              |
   |   Certified rate definition                               |
   |   average_ticket_price :=                                 |
   |       SUM(ticket_revenue) / SUM(tickets_sold)             |
   |   non-additive  ->  recomputed at each consumer grain     |
   |                                                           |
   +-----------------------------------------------------------+
                          |
              inherited verbatim (no re-definition)
                          |
            +-------------+-----------------------+
            |                                     |
            | GROUP BY date                       | GROUP BY channel
            v                                     v
   INHERITED  (same formula, each view at its own grain)

   +---------------------------+     +----------------------------+
   |  DPR semantic view        |     |  Channel Perf. view        |
   |  grain: DAY               |     |  grain: SALES CHANNEL      |
   |                           |     |                            |
   |  SUM(ticket_revenue)      |     |  SUM(ticket_revenue)       |
   |    / SUM(tickets_sold)    |     |    / SUM(tickets_sold)     |
   |  GROUP BY date            |     |  GROUP BY channel          |
   +---------------------------+     +----------------------------+
            |                                     |
            +------------------+------------------+
                               |
                               v
              Reconciliation test (CI)
              - components (revenue, tickets) reconcile at the
                common grain: date x channel, then roll up
              - the rate is compared ONLY at a shared grain;
                a per-day rate and a per-channel rate are not
                directly comparable and must not be asserted equal


   ANTI-PATTERN  (never do this)
   ------------------------------------------------------------
   A view re-chooses a component instead of inheriting:

       SUM(ticket_revenue) / SUM(gross_bookings)
                             ^^^^^^^^^^^^^^^^^^^
                             new denominator = a second definition
                             wearing the first one's name  ->  DRIFT
```

**Reading the flowchart.** The definition sits at the atomic fact grain deliberately: it is below both consumer grains, so a day view and a channel view can each aggregate up to their own grain from the same governed components. Both views hold identical SQL and differ only in their `GROUP BY`. Because the rate is non-additive, only the components are carried down at the fine grain; the ratio is recomputed per view, which is why no view materializes the rate for another to reuse. Reconciliation happens at the common grain (date x channel) on the additive components; the two views' rates are never asserted equal to each other, since they answer different questions. The anti-pattern remains the same regardless of grain: a view swapping in its own numerator or denominator, which reads as inheritance but is really a second definition under the first one's name.
