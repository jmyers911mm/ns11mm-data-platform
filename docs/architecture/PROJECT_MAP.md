# Project Map — Start Here

**A team orientation guide for `ns11mm-data-platform`.** This is the "lay of the land" document: how the project is built, what each part does, where everything lives, where dbt resolves its references, and where a new file should go. It is deliberately a *map*, not a reference manual — when you need depth, it points you to the right document.

> **New to the repo?** Read this top to bottom once (~15 minutes). After that, use it as a lookup: the [Where does my new file go?](#where-does-my-new-file-go) and [Where do I find the answer to…?](#where-do-i-find-the-answer-to) sections are the ones you'll keep coming back to.

> **Current scope:** only the **Gateway + CounterPoint → Daily Performance Report** slice is
> live. All other domains (marketing, CRM/customer-360, membership, donor, GL, ML) are
> scaffolded but `enabled=false`. This map describes the full target layout; the folder
> READMEs under `models/*/` are the source of truth for what is enabled today.

---

## The other docs, and when to read them

This map is the front door. The deep content lives in these companions:

| Document | What it answers | Read it when… |
|---|---|---|
| `README.md` | Full technical reference: every model, every test, lineage, grants, semantic views, Cortex agent | You need the authoritative detail on a specific model, role, or test |
| `CONTRIBUTING.md` | How to make a change: branching, workspace isolation, dev targets, PR checklist, change gates, VQR workflow | You're about to write code and open a PR |
| `ARCHITECTURE_FLOW.md` | The end-to-end platform architecture and data flow narrative | You want the big-picture "how does data get here" story |
| `SOURCE_INTEGRATION.md` | Per-source extraction plans, APIs, and ingestion standards for all source systems | You're working on ingestion or onboarding a new source |
| `TEST_ORCHESTRATION.md` | How tests are scheduled and how failures route to alerts | You're touching test severity, scheduling, or alerting |
| `terraform/README.md` | Infrastructure-as-code layout and deployment | You're changing warehouses, key vault, or alerts |
| `CHANGELOG.md` | What changed and when | You need history or are cutting a release note |

---

## The mental model in 60 seconds

Data flows through a **medallion architecture** — four layers, each with one job. Raw data lands once and is never edited; every transformation happens downstream in dbt; Power BI only displays the finished result.

The schemas are named **RAW → STAGING → INTERMEDIATE → MARTS** (the medallion
Bronze/Silver/Gold pattern, under this project's own names). **Live today** only the
Gateway (ticketing) and CounterPoint (retail POS) sources are connected, feeding the
Daily Performance Report; the other source systems below are scaffolded but disabled.

```
  SOURCE SYSTEMS                 RAW               STAGING             INTERMEDIATE        MARTS                    CONSUMERS
                               (raw landing)     (stg_ views)        (silver_)           (dim_/fct_/rpt_)         (display only)
 ───────────────              ─────────────     ───────────────    ──────────────────  ──────────────────       ─────────────────
  Ticketing/Gateway   ──┐  ◄ LIVE                  models/raw/         silver_gateway__    fct_daily_performance     Power BI  ◄── rpt_ only
  Retail POS (CounterPoint)│  ◄ LIVE   raw_*  ──►   models/raw/    ──►  silver_dpr__   ──►  rpt_daily_performance ──► Cortex   ◄── MARTS.DPR
  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│                       (immutable,         (incremental,       dimensions (dim_)         ML models ◄── ml_ (planned)
  Salesforce CRM/SFMC     │  ◄ planned/disabled    append-only)        tested)             ml_features (planned)
  GA4 / Google / Meta Ads ├──►                                                            reports (rpt_)
  Classy / Blackbaud / Vena┘
```

**Three rules that explain almost every design decision here:**

1. **Bronze is immutable.** Raw data is landed append-only and never modified. If you need to fix something, you fix it in Silver or Gold — never by editing Bronze.
2. **All business logic lives in dbt.** Metric definitions, joins, derivations, segmentation — all of it is SQL in this repo. Power BI is *display-only*; it consumes the `rpt_` tables and adds minimal presentation logic.
3. **The Gold `rpt_` tables are the only thing Power BI should touch.** They are pre-joined and denormalized for BI. `fct_` and `dim_` tables are internal building blocks; `rpt_` tables are the published surface.

---

## How a row travels (the reference chain)

This is the single most important thing to internalize, because it tells you where every model gets its input and how dbt links them together.

```
 RAW.SEED_GATE_JNLTICKETS  (seed load; RAW landing once ingestion is live)
        │   referenced by  →  {{ source('gateway_seed', 'seed_gate_jnltickets') }}
        ▼
 models/raw/stg_gateway__jnltickets.sql            (a VIEW in STAGING schema)
        │   referenced by  →  {{ ref('stg_gateway__jnltickets') }}
        ▼
 models/intermediate/silver_gateway__ticket_journal_lines.sql   (INCREMENTAL in INTERMEDIATE)
        │   referenced by  →  {{ ref('silver_gateway__ticket_journal_lines') }}
        ▼
 models/intermediate/silver_dpr__admissions.sql    (day-grain DPR metric build)
        │   referenced by  →  {{ ref('silver_dpr__admissions') }}
        ▼
 models/marts/facts/fct_daily_performance.sql      (INCREMENTAL table in MARTS)  ◄── joins dim_date via ref()
        │   referenced by  →  {{ ref('fct_daily_performance') }}
        ▼
 models/marts/reports/rpt_daily_performance_report.sql   (the Power BI-facing table)
        ▼
 Power BI / Cortex Analyst via the MARTS.DPR semantic view
```

The rule of thumb: **only staging models use `source()`. Everything downstream uses `ref()`.** This is what lets dbt build the dependency graph (DAG), run things in the right order, and know what to rebuild when something upstream changes.

---

## Repository map — what lives where

Everything below is relative to the repo root. Anything not listed here is either generated (`target/`, `dbt_packages/`, `logs/` — all gitignored) or environment-specific.

| Path | What's in it | Who owns it (CODEOWNERS) |
|---|---|---|
| `dbt_project.yml` | The project's control file: paths, per-layer materialization, schemas, tags, hooks, grants | `@jwmyers82` (Tier 1) |
| `models/` | All dbt models — the heart of the project (see layer breakdown below) | varies by layer |
| `models/raw/` | 21 `stg_*` views live (16 gateway + 5 counterpoint); light renaming/typing only | Data Engineering |
| `models/intermediate/` | 8 `silver_*` incremental models live (gateway/counterpoint + dpr) of 16; cleaned, typed, deduplicated | Data Engineering |
| `models/marts/dimensions/` | 4 `dim_*` live (date, fund, budget_version, marketing_channel) of 10 | Analytics |
| `models/marts/facts/` | 1 `fct_*` live (fct_daily_performance) of 23 | Domain owners + infra |
| `models/marts/reports/` | 1 `rpt_*` live (rpt_daily_performance_report) of 10 — **the Power BI surface** | Analytics |
| `models/ml_features/` | 0 of 14 `ml_*` feature tables live (all disabled pending upstream facts) | Data Science |
| `models/raw/sources.yml` | **The Bronze contract** — declares every raw source table + freshness + source-level tests | Data Engineering |
| `models/*/schema.yml` | Per-folder model docs + tests + contracts (one `schema.yml` per layer folder) | layer owner |
| `models/groups.yml` | dbt model *groups* and their owning teams | infra |
| `models/exposures.yml` | Declares downstream consumers; currently placeholder (exposures removed in 1.3.1 pending re-enabled marts) | infra |
| `macros/generic_tests/` | Reusable custom test macros (e.g. `hashdiff_integrity`, data-quality tests) | infra |
| `macros/operations/` | Operational macros: custom schema naming, forecast creation, VQR sync | `@jwmyers82` (Tier 1) |
| `tests/business_rules/` | 4 singular tests asserting business invariants (no negative revenue, etc.) | reviewer by topic |
| `tests/reconciliation/` | 6 singular tests proving layer-to-layer counts/totals reconcile | reviewer by topic |
| `tests/referential_integrity/` | 12 singular tests proving FKs and seed alignment hold | reviewer by topic |
| `snapshots/` | SCD2 snapshots (planned; land with the CRM/customer domain) | infra |
| `seeds/` | 8 CSVs: `ref_*` reference tables + `seed_*` DPR mapping seeds (tour PLU, retail facility) | infra |
| `semantic_models/` | The live DPR semantic view: `create_dpr_semantic_view.sql` + `dpr.yaml` | infra |
| `terraform/` | Infrastructure-as-code: warehouses, Key Vault, monitor alerts, static web app, deploy pipelines | infra (Tier 1) |
| `.github/workflows/dbt-ci.yml` | The CI pipeline that runs on every PR (Slim CI) | infra (Tier 1) |
| `CODEOWNERS` | Maps paths → required reviewers; enforces the change-gate policy | `@jwmyers82` |
| `.sqlfluff` / `.sqlfluffignore` | SQL linting rules and exclusions | infra |
| `profiles.yml` | Connection profile — **gitignored**, lives only on each developer's machine | each dev |

---

## The layers in detail

Each layer is configured as a block in `dbt_project.yml`. That file is the source of truth for *how* each layer materializes — the table below summarizes it.

| Layer | Folder | Prefix | Materialization | Lands in schema | Purpose |
|---|---|---|---|---|---|
| Staging | `models/raw/` | `stg_` | `view` | `SILVER` | One-to-one with each source; rename, cast, light cleanup. No joins, no business logic. |
| Silver | `models/intermediate/` | `silver_` | `incremental` (merge) | `SILVER` | Cleaned, typed, deduplicated, hashdiff'd. The trustworthy "cleaned" layer. |
| Gold — Dimensions | `models/marts/dimensions/` | `dim_` | `table` | `GOLD` | Conformed dimensions shared across facts (date, customer, product, gate, etc.). |
| Gold — Facts | `models/marts/facts/` | `fct_` | `incremental` (merge) | `GOLD` | Business events and measures. Internal — not consumed by BI directly. |
| Gold — Reports | `models/marts/reports/` | `rpt_` | `incremental` (merge) | `GOLD` | Pre-joined, denormalized, BI-ready. **The published surface for Power BI.** |
| ML Features | `models/ml_features/` | `ml_` | `table` | `ML_FEATURES` | Feature tables for ML/Cortex; granted to `ML_ROLE`. |

A few configured behaviors worth knowing (all set in `dbt_project.yml`):

- Silver and Gold use `+on_schema_change: append_new_columns` — adding a column upstream won't break the build, but it will be added.
- Gold models run a `post-hook` that **grants `SELECT` to `POWERBI_ROLE` and `ML_ROLE`** automatically — you don't hand-grant access to new Gold tables.
- Models land in the schema named by their `+schema:` config *literally* (BRONZE/SILVER/GOLD/ML_FEATURES), because the custom `generate_schema_name` macro in `macros/operations/` overrides dbt's default "target_schema" prefixing.
- Tags (`daily`, `critical`, `intraday`, etc.) drive scheduling and the per-tag statement timeouts in the pre-hook.

---

## Where dbt's references live

If you've ever asked "where is this model getting its data from, and where is that defined?" — here's the full answer.

**Sources (raw Bronze tables) are declared in `models/raw/sources.yml`.**
This file is the contract for everything entering the project. It declares the `bronze` source, points at the `BRONZE` schema, sets freshness windows, and lists every raw table with its columns and source-level tests. A staging model pulls from it with `{{ source('gateway_seed', 'seed_gate_jnltickets') }}`. If a raw table isn't in `sources.yml`, dbt can't see it.

**Model-to-model references use `ref()`, and dbt resolves them automatically.**
You never write a schema or database name in a model body. You write `{{ ref('silver_pos_tickets') }}` and dbt figures out the fully-qualified name and the build order. This is why the DAG is reliable: the references *are* the dependency graph.

**Tests, descriptions, and contracts live in `schema.yml` files — one per layer folder.**
Each layer folder (`staging`, `silver`, `gold/dimensions`, `gold/facts`, `gold/reports`, `ml_features`) has its own `schema.yml`. That's where you declare column descriptions, generic tests (`unique`, `not_null`, `accepted_values`), and custom generic tests (`hashdiff_integrity`, `daily_volume_bounds`, etc.) for the models in that folder. `seeds/schema.yml` does the same for seeds.

**Downstream consumers are declared in `models/exposures.yml`.**
Each Power BI dashboard and ML consumer is registered as an *exposure* that `depends_on` specific `rpt_`/`dim_`/`fct_` models. This makes the lineage complete end-to-end — you can see which dashboard breaks if you change a given report model.

**Ownership and groups: `models/groups.yml` + `CODEOWNERS`.**
`groups.yml` assigns each layer to an owning team (Data Engineering, Analytics, Data Science). `CODEOWNERS` maps file paths to required PR reviewers and enforces the change-gate tiers.

So, the quick lookup:

| To find / change… | Look in… |
|---|---|
| What raw tables exist and their freshness | `models/raw/sources.yml` |
| A model's input data | the `ref()`/`source()` calls in its `.sql` file |
| Column docs and tests for a model | the `schema.yml` in that model's folder |
| Which dashboard depends on a model | `models/exposures.yml` |
| Who must approve a change to a path | `CODEOWNERS` |
| How a layer materializes / where it lands | `dbt_project.yml` |

---

## Where does my new file go?

Use this when you're about to add something and aren't sure where it belongs. Find the row that matches your intent.

| I want to… | Put the file in… | Naming | Then also… |
|---|---|---|---|
| Bring in a brand-new source feed | `models/raw/` as `stg_<source>.sql` | `stg_` prefix | Add the raw table(s) to `models/raw/sources.yml` first |
| Clean / dedupe / type a staged feed | `models/intermediate/` as `silver_<source>.sql` | `silver_` prefix | Add it to `models/intermediate/schema.yml` with tests |
| Add a shared lookup entity (date, product, gate…) | `models/marts/dimensions/` as `dim_<entity>.sql` | `dim_` prefix | Document in `gold/dimensions/schema.yml` |
| Model a business event / measure | `models/marts/facts/` as `fct_<grain>.sql` | `fct_` prefix | Document in `gold/facts/schema.yml`; reference `dim_*` for keys |
| Build something Power BI will consume | `models/marts/reports/` as `rpt_<subject>.sql` | `rpt_` prefix | Register the dashboard in `models/exposures.yml` |
| Create a feature table for ML/Cortex | `models/ml_features/` as `ml_<subject>_features.sql` | `ml_` prefix | Document in `ml_features/schema.yml` |
| Add a reusable test you'll apply in many places | `macros/generic_tests/` | `test_<name>.sql` | Reference it in the relevant `schema.yml` |
| Add a one-off assertion ("this should always be true") | `tests/<category>/` | `assert_<thing>.sql` | Pick the folder: business_rules / reconciliation / referential_integrity |
| Add a small static lookup or reference table | `seeds/` as `ref_<name>.csv` | `ref_` prefix | Document in `seeds/schema.yml` |
| Track history of a slowly-changing entity | `snapshots/` as `snap_<entity>.sql` | `snap_` prefix | Lands in `SILVER`; configured under `snapshots:` in `dbt_project.yml` |
| Save a blessed, reusable analytical query **(planned; VQR library removed in 1.3.1)** | `analyses/verified_queries/<domain>/` | descriptive name | Add an entry to that domain's `_verified_queries.yml` |
| Add infrastructure (warehouse, alert, vault) | `terraform/` (module or env tfvars) | per Terraform convention | Tier 1 change — requires owner approval |

**When you're not sure which layer:** ask "is this cleaning one source, or combining several?" One source → Silver. Combining sources or adding business meaning → Gold. If you find yourself wanting a giant cross-domain combination table, that's usually a sign a conformed `dim_` is missing — add the dimension instead of a mega-table.

---

## Naming conventions at a glance

| Prefix | Meaning | Lives in |
|---|---|---|
| `raw_` | Untransformed source table (Bronze) or sample seed | Bronze / `seeds/` |
| `stg_` | Staging view, 1:1 with a source | `models/raw/` |
| `silver_` | Cleaned, typed, deduplicated model | `models/intermediate/` |
| `dim_` | Conformed dimension | `models/marts/dimensions/` |
| `fct_` | Fact / business event (internal) | `models/marts/facts/` |
| `bridge_` | Many-to-many bridge table | `models/marts/facts/` |
| `rpt_` | Report — Power BI-facing, denormalized | `models/marts/reports/` |
| `ml_` | ML feature table | `models/ml_features/` |
| `ref_` | Reference/lookup seed | `seeds/` |
| `snap_` | SCD2 snapshot | `snapshots/` |
| `assert_` | Singular (one-off) test | `tests/*/` |

---

## Where do I find the answer to…?

| Question | Answer lives in |
|---|---|
| "What does model X do / what are its columns?" | The model's `schema.yml`, or run `dbt docs generate && dbt docs serve` |
| "What's the full lineage of X?" | `README.md` (Model Lineage section) or the dbt docs DAG |
| "How do I set up my dev environment / profile?" | `CONTRIBUTING.md` (Developer Targets + Snowflake CLI setup) |
| "How do I open a PR / who reviews it?" | `CONTRIBUTING.md` (Workflow + Who reviews what) + `CODEOWNERS` |
| "Is this change a Tier 1 (infra) change?" | `CONTRIBUTING.md` (Change Gate Classification) |
| "What sources do we pull and how?" | `SOURCE_INTEGRATION.md` |
| "How do tests get scheduled and alert me?" | `TEST_ORCHESTRATION.md` |
| "Who has access to what in Snowflake?" | `README.md` (Access Control & Grants) |
| "What changed recently?" | `CHANGELOG.md` |
| "How is the warehouse / Key Vault / alerting set up?" | `terraform/README.md` |
| "What's the approved query for metric Y?" | `analyses/verified_queries/` *(planned — removed in 1.3.1)* |
| "Which dashboard will break if I change this model?" | `models/exposures.yml` |

---

## Everyday commands

Run these from the repo root with your virtual environment active. See `CONTRIBUTING.md` for the full workflow and dev-target routing.

```bash
dbt deps                      # install packages
dbt build                     # run + test everything (dev target)
dbt build --select staging    # one layer
dbt build --select fct_daily_performance+   # a model and everything downstream
dbt test                      # tests only
dbt build --full-refresh      # rebuild incrementals from scratch
dbt source freshness          # check Bronze freshness against sources.yml
dbt docs generate && dbt docs serve   # browse the catalog + DAG locally
```

The `+` syntax is your friend: `model+` means "this and everything downstream," `+model` means "this and everything upstream." Use it to scope runs to exactly what your change touches.

---

## Glossary

- **Medallion architecture** — the Bronze → Silver → Gold layering pattern. Each layer raises data quality and business-readiness.
- **Source** — a raw table dbt reads but doesn't build, declared in `sources.yml` and read via `source()`.
- **Model** — a `.sql` file dbt builds into a view or table; references other models via `ref()`.
- **Materialization** — how a model is built: `view`, `table`, or `incremental` (updates only changed rows).
- **Conformed dimension** — a shared dimension (e.g. `dim_date`) used consistently across many facts.
- **Exposure** — a declared downstream consumer (dashboard, ML model) that depends on dbt models.
- **Snapshot** — a model that captures row history over time (SCD2).
- **Seed** — a CSV checked into the repo and loaded as a table; used for small reference data.
- **VQR (Verified Query)** — a certified, reviewed query stored in `analyses/verified_queries/` as the approved way to answer a business question.
- **Singular test** — a one-off `.sql` test in `tests/` asserting a specific condition; contrast with generic tests declared in `schema.yml`.
- **DAG** — the dependency graph dbt builds from all the `ref()`/`source()` calls; it determines run order.
