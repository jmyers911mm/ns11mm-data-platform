# DPR Snowflake Semantic Model

Two equivalent semantic definitions of the Daily Performance Report for Cortex
Analyst (natural-language querying) and native semantic SQL:

| File | What it is | When to use |
|---|---|---|
| `dpr_semantic_view.sql` | Native `CREATE SEMANTIC VIEW` DDL | **Recommended.** Schema-level object (GA March 2026): full RBAC, sharing, catalog, `SEMANTIC_VIEW()` SELECT support. |
| `dpr_semantic_model.yaml` | Cortex Analyst YAML semantic model | REST API (`semantic_model_file` on a stage), `SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML`, and human-readable iteration. |

Keep the two in sync; they describe the same model.

## What it models

Both build a small star over the DPR marts:

```
FCT_DAILY_PERFORMANCE  (additive day-grain fact)  --dpr_to_date-->  DIM_DATE
```

- **Dimensions** come from `DIM_DATE`: report date, year, quarter, month,
  month name, day name, is_weekend, and `is_commemoration_day` (Sep 6-16).
- **Metrics** are `SUM()` aggregations over the additive fact columns, grouped
  into ~17 business KPIs (tickets, admission revenue, attendance, tours, fees,
  audio, retail gross profit, donations).
- **Two ratios** (`avg_ticket_price`, `mus_store_rev_per_visitor`) are
  ratio-of-sums metrics.

## Why build on the fact, not the report layer

`rpt_daily_performance_report` already bakes in MTD/YTD windows and the ratios.
A semantic view should **not** read that: it does its own aggregation, so
feeding it pre-windowed columns would double-count. Building on
`FCT_DAILY_PERFORMANCE` (clean additive grain) lets Cortex Analyst roll up to
**any** period the user asks for (day, month, quarter, year, or "excluding the
commemoration window") instead of only the periods pre-computed in `rpt_`.

## Additive vs non-additive (the ADR, expressed natively)

This is the neat part. The additive/non-additive rule that the dbt layer
enforces by hand becomes a native property of the model:

- **Additive measures** are `SUM()` metrics. Cortex rolls them up correctly at
  any grain automatically.
- **Ratios are ratio-of-sums**: `SUM(numerator) / NULLIF(SUM(denominator), 0)`.
  Because the aggregation happens at the query grain, the ratio is always
  recomputed from summed components and **never** averaged from per-day ratios.
  That is exactly the "non-additive metrics must be computed at query time"
  principle, enforced by the engine rather than by convention.

`avg_ticket_price` over a month = (month ticket rev + month pass rev) / month
tickets, not the mean of 30 daily averages. The model guarantees it.

## Deploy

**Native semantic view (recommended):**
1. Edit `dpr_semantic_view.sql`: replace `NS11MM_DP.MARTS` with your database and
   schema.
2. Run it in a worksheet (or via CI) against the schema holding the marts:
   ```sql
   -- creates NS11MM_DP.MARTS.DPR
   ```
3. Grant Cortex Analyst usage:
   ```sql
   GRANT SEMANTIC VIEW DPR ON SCHEMA NS11MM_DP.MARTS TO ROLE <analyst_role>;
   -- plus SNOWFLAKE.CORTEX_ANALYST_USER on the role that calls the API
   ```
4. Query it directly, or point Cortex Analyst at it:
   ```sql
   SELECT * FROM SEMANTIC_VIEW(
       NS11MM_DP.MARTS.DPR
       DIMENSIONS dt.month_name
       METRICS dp.total_ticket_revenue, dp.avg_ticket_price
   );
   ```
   REST API request body: `{"semantic_view": "NS11MM_DP.MARTS.DPR", ...}`.

**YAML model (REST API / stage):**
1. Edit `dpr_semantic_model.yaml`: replace `NS11MM_DP` / `MARTS`.
2. Upload to a stage and reference it, or materialize it as a semantic view:
   ```sql
   PUT file://dpr_semantic_model.yaml @NS11MM_DP.MARTS.SEMANTIC_STAGE;
   -- REST API body: {"semantic_model_file": "@NS11MM_DP.MARTS.SEMANTIC_STAGE/dpr_semantic_model.yaml"}

   -- or create a native view from it:
   CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
       'NS11MM_DP.MARTS',
       $$<paste YAML or reference stage file>$$
   );
   ```

## Scope and caveats (carried from the marts)

The semantic model inherits the DPR marts' scope. The custom instructions tell
Cortex Analyst to decline gracefully on:

- **Budget / forecast / variance** — not yet modeled (pending budget-source
  staging: AdmissionDailies / RetailDailies).
- **Full Sensource attendance** — `total_museum_attendance` is the scanned
  general-admission component only.
- **Ecommerce gross profit, membership** — out of current scope.

The two ratio metrics and `total_museum_attendance` should be reviewed in the
ADR-005 metric workshop before this is published to business users.

## Notes on the native DDL grammar

- Clause order is strict: `TABLES -> RELATIONSHIPS -> FACTS -> DIMENSIONS ->
  METRICS`. FACTS is omitted here (everything the report answers is a metric
  aggregation grouped by a date dimension).
- The referenced side of a relationship must be a declared `PRIMARY KEY` /
  `UNIQUE`; `DIM_DATE.date_key` is set as the primary key for that reason.
- A query cannot mix FACTS and METRICS in the same `SEMANTIC_VIEW()` clause, and
  metrics must be referenced through aggregation. See Snowflake's semantic view
  querying docs for the SELECT grammar.
- Verified queries are carried in the YAML (stable, documented grammar). They
  can also be attached to the native view via the `AI_VERIFIED_QUERIES` clause
  or added in Snowsight.
