# SQL Style Guide

Conventions for SQL in the `ns11mm-data-platform` project. These are enforced where possible by `.sqlfluff`; the rest is reviewed in PRs. Consistency here is what lets anyone on the team read anyone else's model without friction.

> This guide expands the "SQL Style Guide" section referenced in [CONTRIBUTING](../../CONTRIBUTING.md). When the two differ, this file is authoritative; keep them linked.

---

## Naming conventions

### Model names follow the layer

| Prefix | Layer | Example | Notes |
| --- | --- | --- | --- |
| `stg_<source>__<object>` | Staging | `stg_gateway__transactions` | One staging model per source table. Views in STAGING schema. |
| `silver_` | Silver / Intermediate | `silver_pos_tickets` | Cleansed, business-logic-applied, incremental in INTERMEDIATE schema. |
| `dim_` | Gold dimension | `dim_customer` | One row per entity (customer, date, product…). Table in MARTS. |
| `fct_` | Gold fact | `fct_ticket_sales` | One row per event/grain. In MARTS. |
| `rpt_` | Gold report | `rpt_daily_operations` | Pre-joined, denormalized. **The only MARTS surface Power BI should consume.** |
| `ml_` | ML feature | `ml_donor_churn_features` | Feature-engineered tables in ML_FEATURES schema. |

### Columns

- `snake_case` for everything.
- Primary keys end in `_id` (`customer_id`, `gate_id`).
- Booleans start with `is_` or `has_` (`is_weekend`, `is_discounted`).
- Dates end in `_date`; timestamps in `_at`; counts in `_count`; rates/percentages in `_pct` or `_rate`.
- Monetary columns are unqualified by currency (single-currency platform) but named for what they are (`gross_revenue`, `net_revenue`).

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
    select * from {{ ref('stg_pos_tickets') }}
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

`.sqlfluff` enforces most of this; when in doubt, run the linter.

- **Keywords lowercase** (`select`, `from`, `where`, `join`).
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
- **Use the custom generics** where they apply (`hashdiff_integrity`, `daily_volume_bounds`, `cardinality_change`, etc.) — see the README's testing strategy.
- **Contracts** are enforced on dimension tables; if you change a dimension's shape, update the contract.
- **Incremental models use merge**; set a sensible `unique_key` and respect the `append_new_columns` schema-change policy.
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
