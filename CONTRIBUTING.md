# Contributing

How to make a change to this dbt project safely.

Read sections 1–4 before your first PR. Sections 5–13 are the rules a change is
reviewed against — skim them once, then come back when you hit the specific case.
Sections 14–18 are the process around a change: checklist, review, CI, release.

> **Adapting this file.** Replace every `<PLACEHOLDER>` with your project's real
> value, delete the sections that don't apply, and delete any rule you are not
> willing to enforce. A rule nobody enforces teaches contributors that the rest
> of the document is also optional.

---

## 1. Quickstart

```bash
git clone <REPO_URL> && cd <REPO_NAME>

python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\Activate.ps1
pip install -r requirements.txt                     # pins dbt-core, dbt-<ADAPTER>, dev tools

mkdir -p ~/.dbt
cp profiles.yml.example ~/.dbt/profiles.yml         # then fill in your credentials
dbt debug                                           # must pass before anything else

git config core.hooksPath .githooks                 # repo-managed hooks — see note

dbt deps
dbt build --select +<A_SMALL_MODEL>                 # ancestors first: proves a cold sandbox builds
```

**Version pins.** Python `<PYTHON_VERSION>` and dbt `<DBT_VERSION>`, both matching
CI exactly. Version drift between a laptop and CI produces failures that reproduce
nowhere. The pins live in `requirements.txt`, which CI installs from as well — and
they must pin **`dbt-core` explicitly, not just `dbt-<ADAPTER>`**. Since dbt 1.8
adapters are versioned independently of core, so pinning only the adapter leaves
the core version floating, which is the drift this is meant to prevent.

**Hooks: pick one mechanism.** `git config core.hooksPath .githooks` and
`pre-commit install` are mutually exclusive — `pre-commit` refuses to install
while `core.hooksPath` is set, because it writes into `.git/hooks`. Use
`core.hooksPath` for hand-written repo hooks, or `pre-commit install` for a
`.pre-commit-config.yaml` project. Delete whichever line does not apply here.

**Selector direction matters on a cold sandbox.** `+<model>` selects the model
and its **ancestors**; `<model>+` selects it and its **descendants**. In a fresh,
empty personal database only the first form builds — the second fails on the first
`ref()` to a table that was never built. Once your sandbox is populated,
`<model>+` is the right iteration selector.

**Never commit credentials.** `profiles.yml` lives in `~/.dbt/`, not the repo, and
is listed in `.gitignore`. The repo carries `profiles.yml.example` with placeholder
values only. Secrets reach dbt through environment variables (`{{ env_var(...) }}`).

---

## 2. The daily loop

```bash
git checkout main && git pull                  # start from current main, always
git checkout -b <type>/<short-description>

# ... edit models ...

dbt build --select state:modified+ --defer --state <PROD_ARTIFACTS>
sqlfluff fix models/ && sqlfluff lint models/

git add -A && git commit -m "feat: <what changed and why>"
git push -u origin HEAD
gh pr create --base main
```

**Use `dbt build`, not `dbt run` then `dbt test`.** `build` runs seeds, models,
snapshots, and tests in DAG order, so each node's tests fire immediately after it
is built and downstream models are skipped when an upstream test fails. `run` then
`test` lets bad data propagate through the whole graph before anything complains.

**Build the smallest correct selection.** `--select <model>+` while iterating,
`state:modified+` before pushing. A full `dbt build` on every save is slow and, on
a metered warehouse, expensive.

`state:modified+` compares against a production `manifest.json`, so `<PROD_ARTIFACTS>`
must point at a real one. Fetch the current production artifacts locally with
`<ARTIFACT_FETCH_COMMAND>`; without them the command aborts with *"Got a state
selector method, but no comparison manifest."*

### Branching

Trunk-based. `main` is always deployable. Branches are short-lived — merge within
a few days or split the work. There is no long-running `develop` branch, because
integration branches accumulate conflicts faster than they resolve them.

Branch names use the same vocabulary — `feat/`, `fix/`, `refactor/`, `perf/`,
`test/`, `docs/`, `chore/` + a short kebab-case description.

### Commits

Conventional Commits. The prefix is not decoration — release tooling reads it.

```
feat:     new model, new column, new test, new capability
fix:      corrects wrong output — always say what was wrong
refactor: same output, different implementation
test:     test coverage only
docs:     documentation, descriptions, comments
chore:    dependencies, config, tooling
perf:     measurably faster or cheaper, with the numbers in the body
```

Append `!` (`feat!:`) for a breaking change and explain the break in the body.
See §17 for what counts as breaking here.

Keep PRs single-purpose. A PR that renames columns *and* changes a metric
definition cannot be reviewed properly, and cannot be reverted cleanly.

---

## 3. Environments and targets

| Target | Database / dataset | Role | Who | Purpose |
|---|---|---|---|---|
| `dev` | `<DEV_DB>_<USERNAME>` | `<DEV_ROLE>` | every contributor | personal sandbox |
| `ci` | `<CI_DB>` | `<CI_ROLE>` | CI service account | throwaway PR builds |
| `prod` | `<PROD_DB>` | `<PROD_ROLE>` | deploy automation only | production |

Each contributor builds into their **own** database. Nothing you run locally can
affect anyone else's work, and the isolation is enforced by warehouse permissions,
not by convention — writing to prod with the dev role fails with a permissions
error, by design.

`dev` is the default target. Passing `--target prod` from a laptop should be
impossible; if it is merely discouraged, fix the permissions rather than the
documentation.

**Never hardcode a database, schema, or table name in a model.** Use `{{ ref() }}`,
`{{ source() }}`, and `{{ target }}`. A hardcoded name is a model that builds
correctly in exactly one environment and silently reads the wrong data everywhere
else. This is the single most common cause of "prod numbers don't match dev."

---

## 4. Where a new file goes

| You are adding | Path | Name |
|---|---|---|
| a new source table | `models/staging/<source>/_<source>__sources.yml` | — |
| a staging model | `models/staging/<source>/` | `stg_<source>__<object>.sql` |
| a transformation | `models/intermediate/<domain>/` | `int_<domain>__<verb_phrase>.sql` |
| a dimension | `models/marts/<domain>/` | `dim_<entity>.sql` |
| a fact | `models/marts/<domain>/` | `fct_<event>.sql` |
| a reporting surface | `models/marts/<domain>/` | `rpt_<subject>.sql` |
| a static lookup | `seeds/` | `seed_<subject>.csv` |
| a singular test | `tests/<category>/` | `assert_<what_is_true>.sql` |
| a reusable test | `macros/generic_tests/` | `<test_name>.sql` |
| a macro | `macros/<area>/` | `<verb>_<noun>.sql` |
| a snapshot | `snapshots/` | `snp_<source>__<object>.sql` |

Every model gets a `schema.yml` entry in the same directory, in the same PR.
An undocumented model is an untested model.

### Naming rules

- `snake_case` everywhere, in file names and column names.
- The double underscore in `stg_<source>__<object>` separates *system* from
  *object*, so `stg_shopify__orders` and `stg_netsuite__orders` never collide.
- Primary keys end `_key` (surrogate) or `_id` (natural). Pick one convention
  for surrogates and hold it.
- Booleans start `is_` or `has_`. Dates end `_date`, timestamps `_at`,
  counts `_count`, currency amounts `_amount`, rates `_pct` or `_rate`.
- Do not rename a source system's natural key to fit a house pattern in staging.
  `plu`, `doc_id`, and `sku` should survive into staging under their real names,
  so a human debugging against the source system can find them.
- Never encode grain, filter, or environment in a name: `fct_orders_2024_us` is
  three columns pretending to be a model.

---

## 5. Layering

Four layers, one direction of travel. These constraints are not stylistic — they
are what makes the DAG reason-about-able and what keeps a source change from
rippling into fifty models.

```
sources ────► staging ──► intermediate ──► marts ──► BI / consumers
snapshots ──►    ▲                ▲
seeds ───────────┴────────────────┘
```

| Layer | Reads from | Does | Never does |
|---|---|---|---|
| **staging** | `source()` **only** | rename, cast, cast timezones, trim, deduplicate to source grain | join, aggregate, apply business rules |
| **intermediate** | staging, other intermediate | join, pivot, apply business rules, build the hard parts | get exposed to BI, read from marts |
| **marts** | intermediate, other marts | conform to the business's shape: dimensions, facts, reporting surfaces | contain a rule that belongs upstream |
| **exposures** | marts only | declare a downstream consumer so lineage is complete | — |

Hard rules:

1. **Only staging models and snapshots call `source()`.** Everything else calls
   `ref()`. One and only one staging model per source table. Snapshots are the
   deliberate exception: they read the source directly so they capture
   untransformed state, and downstream models then `ref()` the snapshot.
2. **No layer skipping.** A mart may not read staging directly. If a source
   column needs to reach a mart untouched, it still passes through staging and
   intermediate — the cost is one view, and the benefit is that the DAG tells the
   truth about dependencies.
3. **No upward references.** An intermediate model that `ref()`s a mart inverts
   the graph and makes the build order incomprehensible. If two layers need the
   same logic, push it *down* into a shared intermediate model or a seed — never
   reach up. (A pure calendar spine like `dim_date` is the one widely accepted
   exception, since it has no source dependency.)
4. **Business logic lives in dbt, not in the BI tool.** A metric defined in a
   dashboard is a metric no other consumer can reuse, no test can cover, and no
   lineage can trace. Logic found downstream is a defect to be moved upstream,
   not maintained where it landed.
5. **Marts are the only supported interface.** Consumers bind to `dim_`/`fct_`/
   `rpt_` models. Staging and intermediate are internal and may be restructured
   without notice — that freedom is the entire point of having them.

**Where seeds and snapshots enter.** Seeds are `ref()`-able from any layer — a
mapping table is reference data, not a transformation step, and forcing it through
a passthrough staging view buys nothing. Snapshots enter at the staging layer: read
the snapshot from a `stg_` model and treat that model as the interface, so
downstream consumers are insulated from the snapshot's metadata columns.

If a model is hard to place, the usual cause is that it is doing two jobs.
Split it.

---

## 6. Every model file starts with a header

The header is how a reader understands a model without executing it. It sits at
the very top of the file, above `{{ config() }}`, in `--` line comments.

```sql
-- <Layer>: <one-line statement of what this model is>
-- ---------------------------------------------------------------------------
-- Domain: <business domain>
-- Grain:  one row per <grain>
--
-- <1–5 lines of prose: what it does, which inputs matter, and what it feeds.
-- Name downstream consumers explicitly — "Feeds fct_orders, rpt_daily_sales.">
--
-- Source: <upstream system>                        (optional; staging + dims)
-- NOTE: <caveat, with an owner and a resolution condition>   (optional)
-- MATERIALIZATION: <why this differs from the layer default>  (only if it does)
--
-- <ADR-NNN>: <the governing decision this model must honor>   (where one applies)

{{ config(...) }}
```

- `<Layer>` uses a fixed vocabulary — one of `Staging`, `Intermediate`,
  `Marts dimension`, `Marts fact`, `Marts report`. The tag follows the object's
  prefix, not the folder it happens to sit in.
- `Grain:` is always present and always phrased "one row per …". Most modeling
  bugs are grain bugs, and most grain bugs survive because nobody wrote the grain
  down.
- Caveats use greppable prefixes (`NOTE:`, `TODO:`, `PII:`, `STATUS:`) and each
  one names an owner and the condition that resolves it. A caveat without an
  owner is permanent.
- **No changelog lines, no attribution.** "Renamed col on 3/14, JM" belongs in
  git history, which does not go stale.

Column-level documentation lives in `schema.yml` `description:` fields, not in
SQL comments, so it reaches the docs site and the warehouse's own catalog.

---

## 7. Materialization

**Materialization is set by the layer default in `dbt_project.yml`. A model
overrides its default only when it passes a test below, and the override carries
a header comment naming the reason.**

An explicit `materialized=` that merely restates its layer default should be
deleted. Then the presence of an explicit config means *"this model is an
exception — read the comment,"* which is worth far more than local explicitness.

### Layer defaults

| Layer | Default | Why |
|---|---|---|
| staging | `view` | rename and cast only; no compute worth persisting |
| intermediate | `view` | a logical layer, not a storage layer |
| marts — dimensions, facts | `table` | joined repeatedly; must be fast and stable |
| marts — reports | `view` | thin projections over already-defined measures |

### Override tests

**view → table** requires **both**:

1. **Expensive** — several joins or substantial derivation, *and*
2. **Read more than once** — so a view re-runs that cost on every read.

Either condition alone is not enough. Expensive but read once per build is still
a view (it costs the same either way). Cheap with five consumers is still a view
(five times nearly nothing is nearly nothing).

Count **reads, not just downstream models**. Three `ref()`s in the DAG is three
reads per build; a dashboard querying a view interactively is a read per user per
refresh, which is the case that most often justifies a table at the reporting
edge.

**table → incremental** requires **all three**:

1. **Row grain with a stable unique key** — not an aggregate,
2. **A full refresh is genuinely too slow or too expensive** — measure first;
   incrementality is real complexity and most tables do not need it, and
3. **A documented late-arriving-data strategy** — a lookback window, and a
   scheduled full refresh at a stated cadence.

> **A model that aggregates to a grain must not be `incremental` with `merge`.**
> A `merge` on the grain column over a `sum(...) group by` replaces the stored
> total with only the rows in the current window. When late or corrected rows
> arrive for a period that already exists, the total is silently overwritten with
> a partial one. It does not error. It under-reports, and it keeps under-reporting
> until someone reconciles by hand. If an aggregate genuinely needs
> incrementality, recompute whole periods from full history and replace them:
> `delete+insert` on adapters that support it, `insert_overwrite` on those that
> do not (BigQuery), or the `microbatch` strategy on dbt 1.9+, which is built
> for exactly this shape.

Every incremental model must state its lookback and refresh cadence in the header:

```sql
-- MATERIALIZATION: incremental (merge on order_key), 7-day lookback for late
-- restatements. Restatements older than 7 days need --full-refresh; scheduled
-- monthly. Full rebuild takes ~4 minutes, so a refresh is always safe.
```

### The deletion test, for reporting models

Before materializing a reporting model as a table, ask: *if I deleted this table,
could a consumer reproduce the same numbers from the marts beneath it?*

- **Yes, and it's fast enough** → you did not need the table. Leave it a view.
- **Yes, but too slow** → a legitimate performance materialization. Keep it, and
  say so in the header.
- **No** → logic is hiding in this table that belongs upstream. Move the logic
  down into the fact or intermediate layer. A report that needs to be a table
  because it contains new math is not a materialization decision; it is logic in
  the wrong layer.

`ephemeral` is for small pieces of SQL used by exactly one or two models. It
inlines into consumers, so it does not appear in the warehouse and cannot be
inspected when a number looks wrong. Do not use it for anything you will want to
debug.

---

## 8. Metrics are defined once

The rule everything else in this section follows from: **a metric is defined once
and served many times.**

- **Definition** = the population plus the business rule — which rows count, net
  or gross, which date basis. It lives in dbt at or below the fact grain.
- **Serving** = aggregating an already-defined measure by some grain and slice.
  Serve in as many places as you like.

**New definitions get reviewed; new consumers do not.** A report needing eight
metrics of which six already exist passes six straight through and puts only the
two genuinely new definitions in front of a reviewer.

### Same metric, or a cousin?

When a metric overlaps one that already exists, classify it explicitly:

- **Same** — identical population and rule at a different grain → reuse the
  existing definition verbatim. No new definition.
- **Cousin** — differs in population or rule (net-of-refunds vs gross,
  recognized-date vs transaction-date, includes comps vs excludes) → it gets its
  own **distinct name**, its own definition, and the distinction stated in the PR.

**"Almost the same" is never a valid answer.** The failure mode is specific and
expensive: a cousin ships under the certified name with the difference buried in
a `where` clause, so it reconciles at the total, diverges by slice, and nobody
finds out until a finance meeting.

### Never store a pre-divided rate

Rates do not sum. Storing `conversion_rate` at daily grain and averaging it to a
month gives the wrong answer whenever the daily denominators differ — which is
always.

Carry the **additive components** at the atomic grain and compute
`sum(numerator) / sum(denominator)` at the grain being displayed. Reconcile the
components across grains as ordinary sum checks; reconcile the rate only at a
common grain. *Asserting that a rate reconciles across grains is itself an error.*

**Smell test:** if you are writing a `sum(case when ... end)` that decides *which
rows count as the thing* anywhere except the fact model, stop. That is a
definition, and it has escaped its layer.

---

## 9. Sources, seeds, and snapshots

**Sources** are declared in `_<source>__sources.yml` beside their staging models.
Every source table gets:

- a `description` — what system it comes from and what a row means,
- `loaded_at_field` and a `freshness` block with `warn_after` / `error_after`
  thresholds set from the pipeline's real cadence,
- its database resolved through a variable or `target`, never a literal.

Stale source data is the failure that most often reaches a stakeholder before it
reaches an engineer. `dbt source freshness` is worth running before every
production build.

**Seeds** are for small, static, human-maintained reference data: category
mappings, exclusion lists, business-rule lookups. Under a few thousand rows, and
changing rarely.

- Seeds are **not** an ingestion mechanism. If a file is refreshed on a schedule
  or exceeds a few thousand rows, it belongs in a pipeline landing to a source.
- Every seed gets a `schema.yml` entry with column tests, exactly like a model.
  Seeds change business logic while looking like a data file, which is precisely
  why they need tests.
- Pin `column_types` for anything ambiguous. Type inference will read a leading-
  zero ID as an integer, and it will do it silently.
- A seed change is a **data change**, not a config change. Review it as one.

**Snapshots** capture history for slowly-changing source records that are updated
in place. Prefer `strategy='check'` on explicit columns over `timestamp` when the
source's update timestamp is not trustworthy. Snapshots cannot be rebuilt from
nothing — losing one loses history permanently, so treat the snapshot table as
production data from the day it is created.

---

## 10. Testing

Every model needs, at minimum, a `unique` and a `not_null` test on its primary
key. That pair is what proves the grain in the header is true. A model without it
is documentation, not a guarantee.

### Layers of testing

| Kind | Where | What it catches |
|---|---|---|
| generic (`unique`, `not_null`, `accepted_values`, `relationships`) | `schema.yml` | grain and referential breakage |
| custom generic | `macros/generic_tests/` | a shape you assert repeatedly |
| singular | `tests/<category>/` | one specific business invariant |
| source freshness | `_sources.yml` | upstream stopped delivering |
| unit tests | `schema.yml` `unit_tests:` | transformation logic on fixed inputs |

Organize singular tests by intent, and make the folder mean something:

- `tests/referential_integrity/` — keys resolve, no orphans
- `tests/reconciliation/` — layer-to-layer and source-to-mart totals agree
- `tests/business_rules/` — domain invariants (no negative revenue, no future
  dated events, closed days are zero)

Unit tests deserve special mention: they are the only kind that catches a logic
error in a transformation *before* it meets real data, and the only kind that can
cover a branch your production data does not currently exercise.

### Severity

Default to `error`. Use `warn` deliberately, and only in these cases:

- a non-zero result is a **business finding**, not a code defect (an unmapped
  category means someone must extend a mapping, not that the model is wrong);
- the check is a **drift alert** with a threshold rather than a hard invariant;
- the underlying grain is **inherited from a seed** rather than enforced by the
  model's own `group by`.

**Every `warn` test carries a header comment stating why it is `warn` and what
would promote it to `error`.** Without a promotion condition, a warn is a
permanent shrug — it fires every day, nobody reads it, and eventually it is
noise that hides a real failure.

```sql
-- Test (business_rule): every retail line resolves to a known category.
-- Severity: warn — an unmapped category is a signal to extend seed_category_map,
-- not a build failure. PROMOTE TO ERROR once the map is confirmed complete
-- (owner: <NAME>, target: <DATE>).
```

Set `store_failures: true` on tests whose failing rows you will want to inspect.
Being able to query what failed, without re-running the pipeline, changes
debugging from an afternoon to a minute — but only configure it if the failures
table is real, and delete the claim from this file if it is not.

### Writing a good test

State the assertion affirmatively in the name and header — `assert_<what_is_true>`
— then write SQL that returns the rows violating it. A test named
`test_check_orders` tells a reader nothing at 3am.

Give reconciliation tests an explicit tolerance and say where it came from
(`0.5%`, `$0.01` for float rounding). A tolerance with no stated basis will be
loosened the first time it fires.

---

## 11. SQL style

The formatter settles formatting; review settles clarity. Run
`sqlfluff fix models/ && sqlfluff lint models/` before committing — or whatever
the project's `.sqlfluff` config enforces. Keep the ignore file accurate: a stale
path in `.sqlfluffignore` is a lint gate that quietly stopped running.

Enforced mechanically (see `.sqlfluff`):

- lowercase keywords, functions, identifiers, and types
- consistent indentation and comma placement

Convention, enforced in review:

- **CTE structure**: import CTEs first (one per `ref()`/`source()`), then one
  logical CTE per transformation step, then a `final` CTE. The model ends
  `select * from final`. Many small named CTEs beat one nested query — each name
  is a free explanation, and each CTE is independently selectable while debugging.
- **One column per line** in select lists.
- **Explicit joins** — always write `left join` / `inner join`, never a comma join.
  Always write the `on` clause; never rely on `using` to hide an ambiguity.
- **Qualify every column** with a table alias whenever more than one table is in
  scope. Unqualified columns break silently when an upstream model adds a column
  with the same name.
- **Alias meaningfully.** `orders o` is fine; `a`, `b`, `t1` are not.
- **No `select *`** except in an import CTE or the `final` passthrough. A star in
  the middle of a model means upstream schema changes arrive unannounced.
- **Comment the why, never the what.** `-- excludes internal test orders per
  <RULE>` is useful. `-- filter orders` is noise.

---

## 12. Security and sensitive data

- **No credentials in the repo.** Not in `profiles.yml`, not in a macro, not in
  a commented-out line, not in a test fixture. A committed secret is compromised
  the moment it is pushed — rotate it; deleting the file is not revocation.
- **Never paste real customer data** into a PR description, an issue, a test
  fixture, or a screenshot.
- **Tag sensitive columns** in `schema.yml` so masking, tagging, and access
  policies can be applied programmatically rather than remembered. Declare it
  inside a `config:` block — `config: {meta: {contains_pii: true}}` — which is
  the form dbt is standardizing on; top-level `meta:` and `tags:` on models,
  sources, and columns are on a deprecation path. Check which form your pinned
  `<DBT_VERSION>` expects.
- **Grant on the model, not by hand.** Use dbt's `grants` config so access is
  reviewable in the diff. A model-level `grants:` *replaces* the inherited
  project-level grant — which is exactly what you want for a restricted model
  (`grants={'select': []}` revokes everything the default would have given), and
  exactly what will surprise you if you meant to *add* a role. To extend rather
  than replace, prefix the privilege: `grants={'+select': ['<ROLE>']}`.
- **Adding a sensitive model touches more than one file.** Tag the column, set
  the grant, register it wherever masking policies are applied, and update the
  data classification record — in the same PR. Any list maintained by hand in two
  places will drift, so keep the list of places short and name it here.

---

## 13. Performance and cost

Warehouse compute is usually the dominant line item, and dbt makes it trivially
easy to spend it.

- **Build narrow.** `--select` and `--exclude` are the cheapest optimizations
  available. `dbt build` with no selector, repeatedly, is the most common source
  of surprise spend.
- **Measure before optimizing.** `dbt build` prints per-model timings; the
  warehouse's query history has the rest. Optimize the top three, not the one you
  have a hunch about.
- **Prefer a table over a repeatedly-queried expensive view**, and a view over a
  table nobody reads. §7's override test is a cost rule as much as a design rule.
- **Filter early**, in the CTE closest to the source, not in the final select.
- **Partition/cluster large tables** on the column they are actually filtered by,
  and only once they are large enough for it to matter.
- **Set statement timeouts** so a runaway query fails in minutes rather than
  billing for hours.
- **Know your time-travel window.** It is the real backstop for "we rebuilt prod
  wrong," and it is shorter than most people assume — `<N>` days here. Any
  rollback plan that assumes deep history is fiction.

---

## 14. Before you open a PR

```
[ ] dbt build --select state:modified+ --defer --state <PROD_ARTIFACTS> passes
[ ] sqlfluff lint passes on changed files
[ ] every new/changed model has a schema.yml entry with a description
[ ] every new model has unique + not_null on its primary key
[ ] the header states the grain, and I verified the grain is actually true
[ ] no hardcoded database, schema, or table names
[ ] no credentials, no real customer data anywhere in the diff
[ ] materialization is the layer default, or the header says why it is not
[ ] new metric definitions are called out explicitly in the PR description
[ ] downstream consumers of anything I renamed or dropped are identified
[ ] CHANGELOG entry added under "Unreleased"
[ ] generated artifacts regenerated (docs, semantic layer DDL, etc.)
```

### The PR description

Reviewers need three things, and a diff supplies none of them:

1. **What changed and why** — the ticket, the bug, the request.
2. **How you know it is right** — row counts before and after, a reconciliation
   query and its result, the specific numbers you compared against a known-good
   source. "Tests pass" is table stakes, not evidence.
3. **What else this touches** — the downstream models, dashboards, and consumers
   affected, and whether anything needs a `--full-refresh` after merge.

For anything touching a mart or a metric, state explicitly that objects **outside**
the change's stated scope are unchanged, and show how you checked. Unnoticed
collateral change is the failure mode that a passing test suite is worst at
catching.

---

## 15. Review

`.github/CODEOWNERS` routes reviews automatically. Beyond that:

- **Two people cannot always be found.** If your team is small, say so here and
  define the minimum honestly — which changes may be self-merged, and which may
  never be. A rule requiring four distinct humans on a three-person team is not a
  rule, it is a fiction that will be routed around.
- **Reviewers check reasoning, not just syntax.** Is the grain right? Is this
  metric a cousin of one that already exists? Does this rule belong in this layer?
  CI already checked whether it compiles.
- **Changes to shared upstream models need downstream owners' agreement**, because
  the blast radius is everyone.
- **Tier the risk.** Changes to `dbt_project.yml`, `profiles`, CI configuration,
  schema-generation macros, permissions, or CODEOWNERS change the behavior of
  *every* model at once and deserve a heavier gate than a model edit. Name that
  tier boundary explicitly rather than leaving it to judgment.

---

## 16. CI

Every PR must pass:

| Check | Command | Blocking |
|---|---|---|
| install packages | `dbt deps` | **yes** |
| lint | `sqlfluff lint models/` | **yes** |
| parse | `dbt parse` | **yes** |
| build changed models | `dbt build --select state:modified+ --defer --state <PROD_ARTIFACTS>` | **yes** |
| source freshness | `dbt source freshness` | as configured |

Slim CI requires a production `manifest.json` in the job. Publish it from every
production run and download it at the start of CI.

The failure to guard against is not a missing manifest — a missing one aborts the
run loudly. It is a **stale or wrong** manifest: state comparison then matches no
nodes, dbt logs *"does not match any nodes"*, exits 0, and the PR goes green
having built nothing. Assert that the artifact was actually downloaded and that
its commit matches current production, and consider failing the job on the
no-nodes warning (`--warn-error-options`) so an empty selection is loud too.

> **A documented gate that cannot run is worse than no gate**, because it
> manufactures confidence. Two specific ways this happens, both common:
> a lint step that ends in `|| true` and therefore can never fail; and a
> validation script that checks models which have since been renamed, disabled,
> or deleted, and reports success because it found nothing to check.
>
> Whatever gates you define, define how you will know they still work — and when
> you find a dead one, either fix it or delete the claim from this file. Do not
> leave it standing.

---

## 17. Releasing

**Promotion path:** `dev` → PR + CI → merge to `main` → `prod`.

Deploy from `main` only. Never from a branch, never from a laptop.

### Versioning

Semantic versioning, with "breaking" defined for a data platform — otherwise the
number is decoration:

- **MAJOR** — breaks a consumer. A renamed or dropped column on a mart, a changed
  metric definition, a changed grain. Anything that makes a saved query, dashboard,
  or downstream table wrong. Metric renames are the classic case: they break every
  saved query built on the old name, silently.
- **MINOR** — new models, new columns, new tests. Additive; nothing existing moves.
- **PATCH** — bug fixes and internal refactors with no interface change. A large
  internal restructure is a PATCH if `ref()` names are unchanged and no output
  differs.

The test is *who has to do something*, not how many files changed.

### After deploying

- Run tests against production, not just the build's own tests.
- Compare row counts and key aggregates against the previous known-good state.
- Full-refresh incremental models whose logic changed — an incremental model
  keeps the old definition's rows until it is rebuilt, so a "fixed" model can
  serve a mix of old and new logic indefinitely.
- Promote the `CHANGELOG.md` "Unreleased" entries under a version heading and
  stamp the deploy date. Contributors write the entry at PR time (§14); the
  release stamps it. Neither step alone gives you a changelog you can trust.

**Make "the deployed state matches its changelog" verifiable rather than assumed.**
A changelog describing a deployment that did not fully land is worse than no
changelog: it is a confident, wrong answer to "what is running right now," and
every subsequent investigation starts from it.

### Rollback

Know, per artifact, how each of these comes back:

| Situation | Recovery |
|---|---|
| bad model logic | revert the commit, rebuild the affected selection |
| dropped or replaced table | restore from time travel / backup, then rebuild |
| bad incremental data | `--full-refresh` the model |
| bad seed | fix the CSV, `dbt seed --select <seed>`, rebuild dependents |
| snapshot corruption | **restore from backup — snapshots cannot be recomputed** |

`git revert` plus a rebuild covers views cleanly and covers little else. Write
down the time-to-restore you are actually promising, per surface, and check that
the mechanism exists before you promise it.

---

## 18. Decisions get written down

When a change sets a precedent — a materialization policy, a layering exception,
a metric ownership rule, a choice between two tools — write an ADR in
`docs/adr/ADR_NNN_<short_title>.md` rather than burying the reasoning in a PR
comment where the next person will never find it.

An ADR states: the **context** (what forced the decision), the **decision** in
the imperative, the **options considered** and what was good about the ones you
rejected, the **consequences** including the risks you are knowingly accepting,
and a **revisit trigger** — the concrete condition under which this should be
reconsidered.

Mark status honestly. A `Proposed` ADR that everyone treats as settled is how a
team ends up enforcing a rule nobody agreed to.

---

## Anti-patterns

| Don't | Why | Do instead |
|---|---|---|
| hardcode `prod_db.schema.table` | breaks in every other environment | `ref()` / `source()` |
| `select *` mid-model | schema changes arrive unannounced | list columns |
| business logic in the BI tool | unreusable, untestable, untraceable | define it in dbt |
| a metric defined twice | the two drift, both look right | define once, serve many |
| store a pre-divided rate | rates do not re-aggregate | store components |
| `incremental` + `merge` on an aggregate | silently under-reports late data | `table`, or period replacement (§7) |
| `--full-refresh` in the daily job | expensive, and hides incremental bugs | schedule it deliberately |
| model with no PK test | the grain is a claim, not a guarantee | `unique` + `not_null` |
| a `warn` with no promotion condition | permanent noise that hides real failures | state what promotes it |
| one PR, several purposes | unreviewable, unrevertable | split it |
| a gate that cannot fail | manufactures false confidence | fix it or delete it |

---

## Maintaining this file

This document is only useful while it is true. When a command, path, version, or
gate named here stops matching reality, fixing it is part of the change that broke
it — not a follow-up ticket.

Two habits keep it honest: **do not restate counts** (numbers of models, tests, or
seeds go stale within a sprint — link to the thing instead), and **when you find a
stale instruction, fix it in the same PR** rather than working around it silently.
Every contributor who works around a wrong instruction instead of fixing it teaches
the next one to distrust the whole document.

**Questions:** `<CHANNEL_OR_CONTACT>`