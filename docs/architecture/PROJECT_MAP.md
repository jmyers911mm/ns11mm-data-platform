# Project Map — Start Here

**A team orientation guide for `ns11mm-data-platform`.** This is the "lay of the land" document: how the project is built, what each part does, where everything lives, where dbt resolves its references, and where a new file should go. It is deliberately a *map*, not a reference manual — when you need depth, it points you to the right document.

> **New to the repo?** Read this top to bottom once (~15 minutes). After that, use it as a lookup: the [Where does my new file go?](#where-does-my-new-file-go) and [Where do I find the answer to…?](#where-do-i-find-the-answer-to) sections are the ones you'll keep coming back to.

> **Current scope:** the **Gateway + CounterPoint + report-estate + budget → DPR and
> Pentaho report estate** slice is live (34 staging, 21 intermediate, 13 dims, 11 facts,
> 21 report views, 2 ML feature tables). The remaining domains (marketing,
> CRM/customer-360, membership, donor, GL, most ML) are scaffolded but `enabled=false`.
> The folder READMEs under `models/*/` are the source of truth for what is enabled today.

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

Data flows through four layers, each with one job. Raw data lands once and is never edited; every transformation happens downstream in dbt; Power BI only displays the finished result.

The schemas are named **RAW → STAGING → INTERMEDIATE → MARTS** (+ **ML_FEATURES** and
**SEEDS**). The medallion Bronze/Silver/Gold pattern is the *conceptual* layering only —
nothing in Snowflake is literally named BRONZE/SILVER/GOLD; the schema names above are
the real ones. **Live today:** Gateway (ticketing), CounterPoint (retail POS), the
911dw report-estate tables (attendance/today's-sales/ecommerce/WiFi), and the budget
seeds; the other source systems below are scaffolded but disabled.

```
  SOURCE SYSTEMS                 RAW               STAGING             INTERMEDIATE        MARTS                    CONSUMERS
                               (raw landing)     (stg_ views)        (int_)              (dim_/fct_/rpt_)         (display only)
 ───────────────              ─────────────     ───────────────    ──────────────────  ──────────────────       ─────────────────
  Ticketing/Gateway   ──┐  ◄ LIVE                  models/raw/         int_gateway__       fct_daily_performance     Power BI  ◄── rpt_ only
  Retail POS (CounterPoint)│  ◄ LIVE   seed_* ──►   models/raw/    ──►  int_dpr__      ──►  rpt_daily_performance ──► Cortex   ◄── MARTS.DPR …
  Report estate / budgets │  ◄ LIVE              (immutable,         (views + 4          dimensions (dim_)         ML models ◄── ml_ (2 live)
  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│                        append-only)        tables, tested)     ml_features               Streamlit ◄── rpt_
  Salesforce CRM/SFMC     │  ◄ planned/disabled                                           reports (rpt_)
  GA4 / Google / Meta Ads ├──►
  Classy / Blackbaud / Vena┘
```

**Three rules that explain almost every design decision here:**

1. **RAW is immutable.** Raw data is landed append-only and never modified. If you need to fix something, you fix it in INTERMEDIATE or MARTS — never by editing RAW.
2. **All business logic lives in dbt.** Metric definitions, joins, derivations, segmentation — all of it is SQL in this repo. Power BI is *display-only*; it consumes the `rpt_` models and adds minimal presentation logic.
3. **The `rpt_` models are the only thing Power BI should touch.** They are pre-joined and denormalized for BI. `fct_` and `dim_` tables are internal building blocks; `rpt_` models are the published surface.

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
 models/intermediate/int_gateway__ticket_journal_lines.sql   (a TABLE in INTERMEDIATE)
        │   referenced by  →  {{ ref('int_gateway__ticket_journal_lines') }}
        ▼
 models/intermediate/int_dpr__admissions.sql       (day-grain DPR metric build; a VIEW)
        │   referenced by  →  {{ ref('int_dpr__admissions') }}
        ▼
 models/marts/facts/fct_daily_performance.sql      (a TABLE in MARTS)  ◄── joins dim_date via ref()
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
| `models/raw/` | 34 `stg_*` views live (17 gateway, 7 counterpoint, 2 budget, 2 sensource, 3 shopify, 1 each dpr/ecommerce/wifi); light renaming/typing only | Data Engineering |
| `models/intermediate/` | 21 `int_*` models live (+8 disabled); cleaned, typed, deduplicated; views + 4 tables | Data Engineering |
| `models/marts/dimensions/` | 13 `dim_*` live (+4 disabled) | Analytics |
| `models/marts/facts/` | 11 `fct_*` live (+20 disabled) | Domain owners + infra |
| `models/marts/reports/` | 23 `rpt_*` files: 21 build, 2 gated `enabled=false` narrative sources (+9 disabled) — **the Power BI surface** | Analytics |
| `models/ml_features/` | 2 of 14 `ml_*` feature tables live (12 disabled pending upstream facts) | Data Science |
| `models/raw/sources.yml` + `_budget_sources.yml` | **The RAW contract** — 3 seed-loaded source groups (+ `budget_seeds`) with freshness, resolved via `{{ target.database }}` | Data Engineering |
| `models/*/schema.yml` | Per-folder model docs + tests (one `schema.yml` per layer folder) | layer owner |
| `models/groups.yml` | dbt model *groups* and their owning teams | infra |
| `models/exposures.yml` | 13 exposures — the migrated Pentaho report estate with business + technical owners | infra |
| `macros/generate_schema_name.sql` | Custom schema naming (lives at the `macros/` root) | infra |
| `macros/generic_tests/` | Reusable custom test macro library (available, not yet adopted by any `schema.yml`) | infra |
| `macros/operations/` | Operational macros: forecast creation, deploy validation, GDPR erasure + model-logic macros | `@jwmyers82` (Tier 1) |
| `tests/business_rules/` | 7 singular tests asserting business invariants (no negative revenue, etc.) | reviewer by topic |
| `tests/reconciliation/` | 4 singular tests proving layer-to-layer counts/totals reconcile | reviewer by topic |
| `tests/referential_integrity/` | 1 singular test proving FK integrity holds | reviewer by topic |
| `seeds/` | 19 CSVs: 12 `seed_*` mapping/scope seeds, 5 legacy `ref_*` reference tables, 2 report line-item catalogs (`dpr_line_items`, `retail_line_items`); documented in `seeds/_seeds.yml`; land in the `SEEDS` schema | infra |
| `cortex_project/` | Cortex semantic views (`*.sv.yaml`, source of truth) + agent specs; DDL twins generate to `scripts/deploy_semantic_view_*.sql` | infra |
| `terraform/` | Infrastructure-as-code: warehouses, Key Vault, monitor alerts, static web app, deploy pipelines | infra (Tier 1) |
| `.github/workflows/dbt-ci.yml` | The CI pipeline that runs on every PR (lint + slim build in `NS11MM_DW_DEV_CI`) | infra (Tier 1) |
| `.github/CODEOWNERS` | Maps paths → required reviewers; enforces the change-gate policy | `@jwmyers82` |
| `.sqlfluff` / `.sqlfluffignore` | SQL linting rules and exclusions — enforced in CI | infra |
| `profiles.yml.template` | Copy to `profiles.yml` locally (gitignored) — connection profile lives only on each developer's machine | each dev |

---

## The layers in detail

Each layer is configured as a block in `dbt_project.yml`. That file is the source of truth for *how* each layer materializes — the table below summarizes it.

| Layer | Folder | Prefix | Materialization | Lands in schema | Purpose |
|---|---|---|---|---|---|
| Staging | `models/raw/` | `stg_` | `view` | `STAGING` | One-to-one with each source; rename, cast, light cleanup. No joins, no business logic. |
| Intermediate ("silver") | `models/intermediate/` | `int_` | `view` (4 hot models are `table`) | `INTERMEDIATE` | Cleaned, typed, deduplicated. The trustworthy "cleaned" layer. |
| Marts — Dimensions | `models/marts/dimensions/` | `dim_` | `table` | `MARTS` | Conformed dimensions shared across facts (date, facility, store, product, etc.). |
| Marts — Facts | `models/marts/facts/` | `fct_` | `table` | `MARTS` | Business events and measures. Internal — not consumed by BI directly. |
| Marts — Reports | `models/marts/reports/` | `rpt_` | `view` (`rpt_daily_performance_report` is a `table`) | `MARTS` | Pre-joined, denormalized, BI-ready. **The published surface for Power BI.** |
| ML Features | `models/ml_features/` | `ml_` | `table` | `ML_FEATURES` | Feature tables for ML/Cortex; granted to `ML_ROLE`. |
| Seeds | `seeds/` | `seed_` / `ref_` | seed table | `SEEDS` | Small mapping/reference CSVs checked into the repo. |

A few configured behaviors worth knowing (all set in `dbt_project.yml`):

- Intermediate and marts set `+on_schema_change: append_new_columns` / `+incremental_strategy: merge` as **opt-in defaults** — they only apply if a model opts into `materialized='incremental'` itself.
- MARTS models **grant `SELECT` to `POWERBI_ROLE` and `ML_ROLE`** via dbt's `grants` config (not post-hooks) — a model can override it (`rpt_wifi_email_export` sets `grants: {select: []}`).
- Models land in the schema named by their `+schema:` config *literally* (STAGING/INTERMEDIATE/MARTS/ML_FEATURES/SEEDS), because the custom `generate_schema_name` macro at the `macros/` root overrides dbt's default "target_schema" prefixing. Nothing is literally named BRONZE/SILVER/GOLD — medallion is the conceptual pattern only.
- Tags (`daily`, `critical`, `intraday`, etc.) drive scheduling and the per-tag statement timeouts in the pre-hook.

---

## Where dbt's references live

If you've ever asked "where is this model getting its data from, and where is that defined?" — here's the full answer.

**Sources (raw tables) are declared in `models/raw/sources.yml` (+ `_budget_sources.yml`).**
These files are the contract for everything entering the project. `sources.yml` declares three source groups (`gateway_seed`, `counterpoint_seed`, `report_estate_seed`) pointing at the `RAW` schema via `{{ target.database }}`, with freshness windows per group; `_budget_sources.yml` declares `budget_seeds` in the `SEEDS` schema. A staging model pulls from them with `{{ source('gateway_seed', 'seed_gate_jnltickets') }}`. If a raw table isn't declared, dbt can't see it.

**Model-to-model references use `ref()`, and dbt resolves them automatically.**
You never write a schema or database name in a model body. You write `{{ ref('int_pos_tickets') }}` and dbt figures out the fully-qualified name and the build order. This is why the DAG is reliable: the references *are* the dependency graph.

**Tests and descriptions live in `schema.yml` files — one per layer folder.**
Each layer folder (`models/raw/`, `models/intermediate/`, `models/marts/dimensions|facts|reports/`, `models/ml_features/`) has its own `schema.yml`. That's where you declare column descriptions and generic tests (`unique`, `not_null`, `accepted_values`) for the models in that folder. `seeds/_seeds.yml` does the same for seeds.

**Downstream consumers are declared in `models/exposures.yml`.**
The 13 migrated Pentaho reports are registered as *exposures* that `depends_on` specific `rpt_`/`dim_`/`fct_` models, each with a business owner and technical owner. This makes the lineage complete end-to-end — you can see which report breaks if you change a given model.

**Ownership and groups: `models/groups.yml` + `.github/CODEOWNERS`.**
`groups.yml` assigns each layer to an owning team (Data Engineering, Analytics, Data Science). `.github/CODEOWNERS` maps file paths to required PR reviewers and enforces the change-gate tiers.

So, the quick lookup:

| To find / change… | Look in… |
|---|---|
| What raw tables exist and their freshness | `models/raw/sources.yml` |
| A model's input data | the `ref()`/`source()` calls in its `.sql` file |
| Column docs and tests for a model | the `schema.yml` in that model's folder |
| Which dashboard depends on a model | `models/exposures.yml` |
| Who must approve a change to a path | `.github/CODEOWNERS` |
| How a layer materializes / where it lands | `dbt_project.yml` |

---

## Where does my new file go?

Use this when you're about to add something and aren't sure where it belongs. Find the row that matches your intent.

| I want to… | Put the file in… | Naming | Then also… |
|---|---|---|---|
| Bring in a brand-new source feed | `models/raw/` as `stg_<source>__<entity>.sql` | `stg_` prefix | Add the raw table(s) to `models/raw/sources.yml` first |
| Clean / dedupe / type a staged feed | `models/intermediate/` as `int_<domain>__<entity>.sql` | `int_` prefix (3 legacy models predate the `__` form) | Add it to `models/intermediate/schema.yml` with tests |
| Add a shared lookup entity (date, product, gate…) | `models/marts/dimensions/` as `dim_<entity>.sql` | `dim_` prefix | Document in `models/marts/dimensions/schema.yml` |
| Model a business event / measure | `models/marts/facts/` as `fct_<grain>.sql` | `fct_` prefix | Document in `models/marts/facts/schema.yml`; reference `dim_*` for keys |
| Build something Power BI will consume | `models/marts/reports/` as `rpt_<subject>.sql` | `rpt_` prefix | Register the dashboard in `models/exposures.yml` |
| Create a feature table for ML/Cortex | `models/ml_features/` as `ml_<subject>_features.sql` | `ml_` prefix | Document in `models/ml_features/schema.yml` |
| Add a reusable test you'll apply in many places | `macros/generic_tests/` | `<name>.sql` (no `test_` filename prefix) | Reference it via `data_tests:` in the relevant `schema.yml` |
| Add a one-off assertion ("this should always be true") | `tests/<category>/` | `assert_<thing>.sql` (error) / `alert_<thing>.sql` (warn) | Pick the folder: business_rules / reconciliation / referential_integrity |
| Add a small static lookup or mapping table | `seeds/` as `seed_<name>.csv` | `seed_` prefix (5 legacy `ref_*` seeds remain) | Document in `seeds/_seeds.yml` |
| Save a blessed, reusable analytical query **(planned; VQR library removed in 1.3.1)** | `analyses/verified_queries/<domain>/` | descriptive name | Add an entry to that domain's `_verified_queries.yml` |
| Add infrastructure (warehouse, alert, vault) | `terraform/` (module or env tfvars) | per Terraform convention | Tier 1 change — requires owner approval |

**When you're not sure which layer:** ask "is this cleaning one source, or combining several?" One source → intermediate. Combining sources or adding business meaning → marts. If you find yourself wanting a giant cross-domain combination table, that's usually a sign a conformed `dim_` is missing — add the dimension instead of a mega-table.

---

## Naming conventions at a glance

| Prefix | Meaning | Lives in |
|---|---|---|
| `SEED_*` (tables) | Untransformed source table loaded into `RAW` | Snowflake `RAW` schema (declared in `sources.yml`) |
| `stg_` | Staging view, 1:1 with a source | `models/raw/` |
| `int_` | Cleaned, typed, deduplicated model (`int_<domain>__<entity>`) | `models/intermediate/` |
| `dim_` | Conformed dimension | `models/marts/dimensions/` |
| `fct_` | Fact / business event (internal) | `models/marts/facts/` |
| `bridge_` | Many-to-many bridge table | `models/marts/facts/` |
| `rpt_` | Report — Power BI-facing, denormalized | `models/marts/reports/` |
| `ml_` | ML feature table | `models/ml_features/` |
| `seed_` | Mapping/scope seed CSV | `seeds/` |
| `ref_` | Reference/lookup seed (legacy naming; new seeds use `seed_`) | `seeds/` |
| `assert_` / `alert_` | Singular (one-off) test — error / warn severity | `tests/*/` |

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
dbt source freshness          # check RAW freshness against sources.yml
dbt docs generate && dbt docs serve   # browse the catalog + DAG locally
```

The `+` syntax is your friend: `model+` means "this and everything downstream," `+model` means "this and everything upstream." Use it to scope runs to exactly what your change touches.

---

## Glossary

- **Medallion architecture** — the Bronze → Silver → Gold layering pattern. Each layer raises data quality and business-readiness. Conceptual only here: the actual schemas are RAW/STAGING/INTERMEDIATE/MARTS.
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
