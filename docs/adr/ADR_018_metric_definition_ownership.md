# ADR-018: Metric Definition Ownership Across Semantic Views and Report Models

- **Status:** Proposed
- **Date:** 2026-07-13
- **Deciders:** Jeremy Myers (VP AI & Analytics)
- **Sharpens:** ADR-005 (Metric Gate)
- **Related:** ADR-004 (No logic in Power BI)

---

## Context

ADR-005 established that a metric definition must precede any engineering build. That rule was authored when the platform had a single flagship consumer: the Daily Performance Report (DPR), served by one `rpt_dpr` table and one DPR semantic model of 36 metrics. Under those conditions it was sufficient to say the semantic model was the definitional home for a metric, because there was only one of them.

That assumption no longer holds. As additional report domains come online (Attendance, Retail, Fundraising, Membership, Marketing, Finance), each will bring its own `rpt_` models and, in several cases, its own semantic view. Many of these will surface metrics that already exist in the DPR: `tickets_sold`, `ticket_revenue`, `donations`, and similar core measures will legitimately appear in more than one report.

This creates a drift surface that ADR-005 does not address. Two semantic views that each carry their own expression for `tickets_sold` will diverge exactly the way two hand-built SSRS reports diverged: independently, silently, and discovered late in a stakeholder meeting rather than at build time. Designating "the semantic view" as the definitional home does not solve this once semantic views are plural; it only relocates the drift from `rpt_`-versus-`rpt_` up to view-versus-view.

The platform's stated success criterion is a single trusted source of truth across all source systems. That criterion is about **definitions being singular, not artifacts being singular.** A metric may be *served* by many artifacts. It must be *defined* in exactly one place. This ADR fixes where that place is and what the surrounding artifacts are permitted to contain.

---

## Decision

### 1. Metric definitions live once, upstream, at or below the fact grain

The definitional core of a certified metric (its population, its measure, and its business rules, for example recognized-date basis, `JnlcodeID=101`, `trim(plu)` normalization, and whether it is net of comps) lives in dbt at or below the fact-table grain. The preferred form is a governed column on the fact table (for example a `ticket_count` measure or an `is_billable` flag on `fct_ticket_sales`) so that the expensive, error-prone logic exists exactly once, is tested once, and is never retyped downstream.

Metric logic must not originate in a semantic view or in an `rpt_` model.

For a non-additive metric (a rate, ratio, or average), the governed upstream objects are its **additive components** (numerator and denominator), and the certified definition additionally records the pairing and formula (for example `average_ticket_price` is defined as `SUM(ticket_revenue) / SUM(tickets_sold)`, marked non-additive). The ratio is computed at the grain being viewed, at exposure time, because a rate cannot be pre-aggregated and re-summed. Storing a rate as a per-row or per-partition number and re-aggregating it downstream is prohibited.

### 2. Semantic views expose metrics; they do not define them

One semantic view may define a metric only if no upstream definition exists and no other view exposes it. The moment a metric appears in more than one semantic view, its definition consolidates one layer below the views, into dbt, and the views become exposure surfaces over that shared definition.

Semantic views are thin by mandate. A view's declaration of a shared metric resolves to a trivial aggregation over the governed upstream column (for example `SUM(ticket_count)` or `COUNT(*)` over a governed population), differing across views only in grain and dimensional slicing. A semantic view that contains real derivation logic (a `SUM(CASE WHEN ...)` re-encoding a population, a filter that changes which rows a metric counts) is a defect and is rejected in review.

### 3. `rpt_` models are projections, never re-derivations

An `rpt_` table is a materialization of already-defined metrics: a cache for a hot dashboard, a specific shape, or a pinned snapshot. It selects from facts, dimensions, and where appropriate from a semantic view. It introduces no new aggregation math and no new population filter that alters a certified metric. An `rpt_` that re-derives a metric is a quiet ADR-005 violation, technically inside dbt yet redefining certified logic, and is rejected in review.

`rpt_` models must not select from other `rpt_` models. Report-on-report coupling, where a fix to `rpt_dpr` silently breaks three downstream reports, is prohibited.

> **Superseded by ADR-021 (2026-08-10).** The enumerated amendment below fell out of date twice
> in twelve days as the serving chains grew from six models to roughly twenty. ADR-021 replaces it
> with a role-based rule keyed on model-name suffix, which covers new reports without amendment.
> The original text is retained for the record:
>
> **Amendment (2026-07-29, pending committee ratification):** thin projection/serving chains off the semantic-view wrapper reports (`rpt_*_powerbi`, `rpt_*_budget_daily`) are exempt — they add no new business logic, only shape. This covers the narrative-brief and report-long chains (`rpt_dpr_narrative_brief`, `rpt_retail_narrative_brief`, `rpt_dpr_report_long`, `rpt_retail_report_long`, and the disabled `rpt_dpr_narrative` / `rpt_retail_narrative`), which read `rpt_dpr_powerbi` / `rpt_retail_powerbi` and `rpt_dpr_budget_daily` / `rpt_retail_budget_daily`. New metric logic in an `rpt_` still violates this rule.

### 4. The same-versus-cousin rule

When a metric in a new report overlaps a certified metric, the build must first classify it:

- **Same metric.** It is the certified metric under a different grain or slice. It reuses the existing definition verbatim by referencing the same upstream measure. No new definition is created. This is pure exposure and does not pass through the ADR-005 gate.
- **Cousin metric.** It resembles a certified metric but differs in population or rule (for example net-of-comps versus gross, recognized-date versus transaction-date). It is a distinct certified metric. It receives a distinct name and its own definition, and it passes through the ADR-005 gate.

"Almost the same" is not an allowed outcome. A cousin metric that ships under the certified metric's name, with the difference hidden inside a view or `rpt_` filter, is the most damaging failure mode this ADR exists to prevent: it manufactures two metrics wearing one name and looks reconciled while being wrong. When overlap is detected, classification is the first question in PR review, and it must be answered explicitly and recorded.

### 5. Canonical metric catalogue as the generation source (target state)

Past three or so semantic views, "same metric equals same expression" stops being enforceable by discipline. The platform moves to a single canonical metric catalogue that names each certified metric, its owner, its upstream governed source column, and its expression. Semantic views and the Cortex Analyst semantic model are generated from the catalogue rather than hand-authored. At that point a rogue redefinition of `tickets_sold` becomes structurally impossible rather than merely discouraged.

Until the catalogue-and-generate mechanism is in place, rules 1 through 4 are enforced by reconciliation tests (below) and PR review.

### 6. The ADR-005 gate applies per metric, not per report

The metric gate fires on **new definitions**, never on **new consumers of existing definitions**. A report requesting eight metrics, six of which already exist, passes six through as pure exposure and sends only the two genuinely new definitions through the gate.

---

## Enforcement

**Reconciliation tests in CI.** For every metric declared identical across artifacts, a CI assertion confirms that all exposures reconcile to the shared upstream measure at a common grain. This begins with `rpt_dpr` versus the DPR semantic view and widens to every cross-view shared metric. Where all exposures reference the same governed fact column, the test is nearly structural: it asserts that no artifact slipped in a redefining filter. Drift becomes a red build rather than a late discovery.

For non-additive metrics, reconciliation takes a different form and must not assert equality across grains. Two checks apply: the additive components reconcile across grains as ordinary sum checks, and the rate itself reconciles only at a common grain, where every exposure must return the same `SUM(numerator) / SUM(denominator)`. Asserting that a rate reconciles across grains is itself an error.

**Immediate action: reconcile the DPR before report number two.** `rpt_dpr` predates the DPR semantic model in likelihood, having been built to match Pentaho DPR output, with the semantic layer fitted afterward. The two may already disagree at the flagship. Reconciliation runs now, before any second report inherits an ambiguity that already exists.

**PR review checklist.** Reviewers confirm, for any change touching an `rpt_` model or semantic view:
1. No new aggregation or population filter re-derives a certified metric.
2. Any overlapping metric has been explicitly classified same or cousin, and cousins carry a distinct name.
3. No `rpt_` selects from another `rpt_`.
4. New definitions (and only new definitions) have passed the ADR-005 gate.

---

## Consequences

**Positive.**
- Single source of truth becomes enforced by machinery and structure rather than by memory.
- Semantic views stay thin and therefore auditable; Cortex Analyst benefits from unambiguous, conformed measures.
- The gate no longer taxes reuse, so onboarding a new report that reuses existing metrics is cheap.
- The same-versus-cousin rule surfaces genuine metric distinctions that would otherwise hide as silent filters.

**Costs and tradeoffs.**
- Upfront work to consolidate the DPR definition below the semantic view and to reconcile `rpt_dpr` against it.
- The reconciliation-test surface grows with each shared metric. This is intended: the tests are the enforcement.
- The catalogue-and-generate mechanism is real engineering. Until it lands, plural views lean on review discipline plus reconciliation tests, which is workable to roughly three views and strained beyond.
- Pushing logic to the fact grain occasionally requires reshaping a fact model so that a metric is a governed column rather than an ad hoc expression. This is the correct place for the cost to land.

**Neutral.**
- Redundant serving of a metric across many artifacts remains fully acceptable and is often necessary for performance. Only redundant defining is forbidden.
