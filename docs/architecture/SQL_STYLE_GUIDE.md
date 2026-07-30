# SQL Style Guide

Conventions for SQL in the `ns11mm-data-platform` project. These are enforced where possible by `.sqlfluff`; the rest is reviewed in PRs. Consistency here is what lets anyone on the team read anyone else's model without friction.

> This guide expands the "SQL Style Guide" section referenced in [CONTRIBUTING](../../CONTRIBUTING.md). When the two differ, this file is authoritative; keep them linked.

---

## Naming conventions

### Model names follow the layer

| Prefix | Layer | Example | Notes |
| --- | --- | --- | --- |

| `stg_<source>__<object>` | Staging | `stg_gateway__tickets` | One staging model per source table. Views in STAGING schema. |
| `int_<domain>__<entity>` | Silver / Intermediate | `int_gateway__ticket_journal_lines` | Cleansed, business-logic-applied. Views (4 hot models are tables) in INTERMEDIATE schema. Three legacy models (`int_pos_tickets`, `int_ticket_inventory`, `int_ticket_scans`) predate the `__` form and are kept to avoid churning refs. |
| `dim_` | Gold dimension | `dim_customer` | One row per entity (customer, date, product…). Table in MARTS. |
| `fct_` | Gold fact | `fct_daily_performance` | One row per event/grain. In MARTS. |
| `rpt_` | Gold report | `rpt_daily_performance_report` | Pre-joined, denormalized. **The only MARTS surface Power BI should consume.** |
| `ml_` | ML feature | `ml_ticket_demand_features` | Feature-engineered tables in ML_FEATURES schema. |

### Columns

- `snake_case` for everything.
- Key naming, as practiced in this repo: **dimension/fact join keys end in `_key`**
  (`date_key`, `key_facility` for the legacy 911dw surrogate); staging and
  intermediate models **carry the source system's natural ids as-is**
  (`ticket_id`, `doc_id`, `plu`, `item_no`). Don't rename a natural key to force
  an `_id` suffix.
- Booleans start with `is_` or `has_` (`is_weekend`, `is_commemoration_day`) — plus the legacy `ga_flag`.
- Dates end in `_date` or `_key` when they are the day-grain join key; timestamps in `_at`; counts in `_count`; rates/percentages in `_pct` or `_rate`.
- Monetary columns are unqualified by currency (single-currency platform) but named for what they are (`gross_revenue`, `net_sales`, `net_profit`).

---

## Layering rules (non-negotiable)

1. **Staging reads only from sources.** Never from another model.
2. **Silver reads from staging** (and other silver where necessary).
3. **Gold reads from silver** and other gold.
4. **`rpt_` models are the only Gold tables exposed to Power BI.** `fct_` tables are internal; surface them through an `rpt_`.
5. **No skipping layers** — Gold should not read directly from staging.
6. **No business logic in Power BI.** Logic lives in dbt so the definition is single-sourced.

---

## Model structure

Use CTEs, top to bottom, in a predictable order:

```sql
with

source as (
    select * from {{ ref('stg_gateway__tickets') }}
),

renamed as (
    select
        ticket_id,
        lower(trim(email))      as email,
        ticket_type,
        sale_amount
    from source
),

final as (
    select
        *,
        case when sale_amount = 0 then true else false end as is_free_admission
    from renamed
)

select * from final
```

- **Import CTEs first** (`ref()` / `source()`), one per upstream.
- **Logical CTEs** in the middle, each doing one clear thing.
- **A `final` CTE** that the model selects from. The model always ends with a single `select * from final`.
- Prefer many small, named CTEs over one deeply nested query.

---

## Formatting

The repo `.sqlfluff` **exists and is enforced in CI** (the lint job fails the PR).
What it enforces, exactly:

- **Capitalisation rules** — lowercase policy for keywords, identifiers, functions,
  literals, and types.
- **Convention rules** — all except CV11 (casting style: Snowflake `::` and
  `cast()` are both in use, so CV11 is excluded).
- **Jinja rules.**
- **Excluded wholesale:** `layout`, `aliasing`, `structure`, `references`,
  `ambiguous` — judged too noisy against the existing (readable, reviewed) model
  formatting. Those aspects are reviewed in PRs instead.
- Dialect `snowflake`, jinja templater with dbt builtins, no max line length, no
  large-file skip (the biggest staging model is linted too).

House style the linter does not enforce (PR review does):

- **One column per line** in select lists; trailing commas are fine if the linter allows, otherwise lead.
- **Indent** CTE bodies one level.
- **Explicit joins** — always state the join type (`left join`, `inner join`); never rely on implicit comma joins.
- **Qualify columns** with table aliases in any query with more than one table.
- **Reference, never hardcode** — use `{{ ref() }}` and `{{ source() }}`, never database/schema/table literals.
- **No `select *` in production models** except inside import CTEs and the final passthrough.

Run before committing:

```
sqlfluff lint models/
sqlfluff fix models/    # auto-fixes what it can
```

---

## dbt-specific expectations

- **Every model needs a `schema.yml` entry** with a description and at least primary-key tests (`not_null`, `unique`).
- **Add a `group`** config for models that belong to a domain (see Ownership Zones in CONTRIBUTING).
- **Use `accepted_values`** on categorical columns (ticket types, statuses, tiers).
- **Use the custom generics** where they apply (`hashdiff_integrity`, `daily_volume_bounds`, `cardinality_change`, etc.) — the library in `macros/generic_tests/` is available but not yet adopted by any `schema.yml`; adopt via `data_tests:` as sources are verified.
- **Contracts** are **not yet enforced** — no model carries a `contract:` config today. Planned: enforce on dimension tables once shapes stabilize.
- **Models that opt into incremental use merge**; set a sensible `unique_key` and respect the `append_new_columns` schema-change policy (both are opt-in defaults in `dbt_project.yml` — the layer defaults are views/tables, not incremental).
- **Document new business logic with a test.** If a rule matters (no negative revenue, rates ≤ 100%), assert it.

---

## Commit and PR hygiene

Follow the commit prefixes from [CONTRIBUTING](../../CONTRIBUTING.md#commit-messages):

```
feat:     new model or capability
fix:      bug fix
refactor: restructure without behavior change
test:     add or change tests
docs:     documentation only
```

Keep PRs small and single-purpose. Run the [Pre-PR Checklist](../../CONTRIBUTING.md#pre-pr-checklist) before opening.
