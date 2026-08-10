# ADR-020: Materialization is set by layer default, and overridden only for a stated reason

**Status:** Proposed
**Date:** August 10, 2026
**Deciders:** Jeremy Myers (Data & AI Team lead)
**Consulted:** —

## Context

`dbt_project.yml` sets a materialization for every layer: staging `view`, intermediate
`view`, marts dimensions and facts `table`, marts reports `view`, ML features `table`.
Those defaults have been in place since the 7.x restructure and the tree conforms to them
closely — of 127 active models carrying an explicit `materialized=` config, 121 restate
their own layer default and only 6 are genuine overrides.

The problem is not drift. It is that **no document says how to choose.** `README.md`,
`docs/architecture/PROJECT_MAP.md`, and `docs/README.md` each carry a table describing what
the materializations *are*, including the parenthetical "4 hot models as tables." None
says what makes a model one of those four. `docs/architecture/BUILD_DIMS_METS.md` is the
only prescriptive text in the repo, and its decision tree — "do you need a materialization
for a nameable reason?" plus the deletion test, "if you deleted it, could you reproduce the
same numbers through the semantic view?" — covers only the `rpt_` layer.

The consequences of that gap are already visible in two places. The rule governing the
largest set of models, the intermediate view-to-table promotion, exists solely as four
near-identical header comments in the models that took it. And the rule that keeps
day-grain facts out of `incremental` exists in exactly one place: a comment in
`fct_daily_operations.sql` written after an incremental `merge` on `visit_date` silently
overwrote a day's totals with only the newly-arrived slice — a real undercount bug in the
7.x series. Neither rule survives the departure of the person who wrote the comment.

There is also a cost question. Snowflake is roughly $42K/year and the cost model is
compute-dominant, not storage-dominant. That asymmetry is what makes "table" the cheap
answer for anything recomputed repeatedly and "view" the cheap answer for everything else;
a materialization policy written for a storage-dominant warehouse would come out
differently.

What is not yet known: whether report-layer read volume after the December 2026 go-live
will hold `rpt_` models at views. Today the Power BI surfaces are thin projections and the
views are fast. At production concurrency some may not be.

## Decision

Materialization is set by the layer default in `dbt_project.yml`. A model overrides its
layer default **only when it satisfies a stated test below, and the override carries a
header comment naming the reason.** An explicit `materialized=` config that merely repeats
its layer default should be removed, so that the presence of an explicit config means "this
model is an exception — read the comment."

**Layer defaults**

| Layer | Default | Why |
|---|---|---|
| `models/raw/` | `view` | Rename and cast only; no compute worth persisting |
| `models/intermediate/` | `view` | Silver is a logical layer, not a storage layer |
| `models/marts/dimensions/` | `table` | Points of join for every fact; must be fast and stable |
| `models/marts/facts/` | `table` | Business events, joined repeatedly downstream |
| `models/marts/reports/` | `view` | Projections over already-defined metrics (ADR-004); no new math, so nothing to persist |
| `models/ml_features/` | `table` (transient) | Snowflake ML FORECAST requires a physical table |

**Override tests**

*Intermediate `view` → `table`* requires **both**:

1. **Expensive to compute** — several joins, or substantial derivation logic, and
2. **More than one consumer** — so a view re-runs that cost once per consumer.

Either alone is insufficient. `int_dpr__fees_and_services` has four joins but one consumer
and stays a view; `int_ticket_scans` has three consumers but no joins and stays a view.
The four models that pass both — `int_counterpoint__retail_lines` (5 joins, 4 consumers),
`int_gateway__ticket_journal_lines` (6, 3), `int_gateway__item_journal_lines` (4, 2), and
`int_gateway__ticket_demand_features` (~120 lines of derivation, 2) — are the worked
examples.

*Report `view` → `table`* requires computation a view would redo on every read, and passes
the `BUILD_DIMS_METS.md` deletion test. `rpt_daily_performance_report` is the only current
case: eleven window functions for MTD/YTD roll-ups plus non-additive ratio recomputation at
report grain. The five `rpt_*_powerbi` surfaces have zero windows and zero joins and remain
views. A report that needs a table because it contains new math is not a materialization
decision — it is logic in the wrong layer, and the logic moves upstream (ADR-004).

*Fact `table` → `incremental`* requires **row grain with a stable unique key**.
`fct_ticket_availability` qualifies: merge on `availability_key`, 7-day lookback,
documented monthly full-refresh. **A model that aggregates to a grain must not be
incremental.** A `merge` on the grain column over a `sum(...) group by` that column
replaces the stored total with only the rows in the current window, which undercounts
silently whenever late or corrected rows land for an existing period. If an aggregate model
genuinely needs incrementality, it uses `delete+insert` on the affected periods recomputed
from full history — not `merge`.

## Options considered

### Option A: layer defaults plus a documented override test (selected)

Codifies what the tree already does, so adoption cost is a documentation change and the
removal of redundant configs rather than any model rebuild. It keeps the judgment where
judgment belongs — an engineer still decides whether a model is "expensive" — while making
the two conditions explicit enough that a reviewer can ask for both. The worked examples
carry most of the weight: six real models with their join and consumer counts are easier to
reason against than a rule in the abstract.

### Option B: numeric thresholds (set aside)

State the intermediate rule as a hard threshold — for example, "≥3 joins and ≥2 consumers
means table." Its genuine advantage is that it is mechanically checkable: a CI script could
enforce it, and it removes the argument about what counts as expensive, which is exactly the
kind of argument that produces inconsistency over time.

Set aside because the threshold misclassifies a model already in the tree.
`int_gateway__ticket_demand_features` has one join and would fail any join-count rule, yet
it is correctly a table — its cost is ~120 lines of feature derivation, not joins. A
threshold that needs an exception on the day it is written is weaker than the judgment test
it replaces. Worth revisiting if the intermediate layer grows past roughly 40 models, where
per-model review stops being reliable.

### Option C: materialize everything as tables (set aside)

The simplest possible policy, and it has a real advantage: predictable read performance
everywhere, no surprise when a view over a view over a view turns out to be slow at
production concurrency, and no judgment call for anyone to get wrong.

Set aside because it inverts the cost model. On compute-dominant Snowflake pricing, every
persisted model pays build compute on every daily run whether or not anything reads it —
and most staging and intermediate models are read once, by one downstream model, in the same
run that built them. It would also break the ADR-004 boundary in practice: once reports are
tables, a "just this once" calculation in a report stops being visibly wrong, which is how
the legacy Pentaho estate accumulated its duplication.

## Consequences

**Positive**

- The intermediate promotion rule and the aggregate-grain incremental prohibition move from
  header comments into a citable decision. Both currently depend on one person's memory.
- Review gets a specific question to ask — "which of the two conditions does this meet?" —
  instead of a general impression of whether a materialization looks right.
- Removing the 121 redundant configs makes an explicit `materialized=` meaningful. Today the
  six real overrides are invisible in a grep, and changing a layer default silently changes
  nothing because every model restates it.

**Negative**

- "Expensive to compute" stays a judgment call. Two engineers can disagree about a model
  with three joins and two consumers, and this ADR does not settle that case.
- Removing redundant configs means a future change to a layer default in `dbt_project.yml`
  will actually take effect across every model in that layer. That is the point, but it makes
  `dbt_project.yml` a genuinely higher-blast-radius file than it is today — it is already
  Tier 1 under CONTRIBUTING.md and should stay there.
- The policy is silent on `ephemeral`, which the project does not currently use. A future
  case for it is not covered here.

**Accepted risks**

- Report-layer views may not hold at production concurrency after go-live. The policy
  accepts that risk now in exchange for keeping logic visible, and `rpt_daily_performance_report`
  is the precedent for promoting a specific report when it is measured to need it.
- Removing redundant configs is a wide, low-risk diff across roughly 120 files. It should
  land as its own PR with a `dbt build` and a manifest comparison confirming no
  materialization actually changed, not folded into a feature branch.

## Revisit trigger

Reopen this ADR when any of the following occurs:

- The active intermediate layer passes **40 models** (21 today), at which point per-model
  judgment stops scaling and Option B's numeric threshold becomes the better trade.
- A Power BI report backed by an `rpt_` **view** is measured above the ADR-016 interactive
  response target at production concurrency after the December 2026 go-live — that is
  evidence the reports-are-views default no longer holds and the promotion criteria need
  restating.
- Ingestion moves off the seed-based interim path (ADR-019, ADR-003), giving staging models
  real incremental volume rather than full-extract reloads. The staging-is-always-a-view
  default is written for full extracts and should be re-examined against streams.
