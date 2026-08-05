# ADR-008: Semantic Layer Governance: Snowflake Semantic Views as the Metric Layer, Definitions Governed in dbt

**Status:** Proposed (drafted from the ADR Review working document, **revised against the semantic-views finding**; decision pending the Jeremy/Diana review session)
**Category:** AI / Analytics
**Date:** August 5, 2026
**Deciders:** Jeremy Myers (VP AI & Analytics)
**Consulted:** Diana (Data & AI Team)
**Related:** ADR-005 (Metric Definition Gate), ADR-018 (Metric Definition Ownership), ADR-004 (No Logic in Power BI), ADR-009 (Reporting Tiers), ADR-014 (Change Validation)

> **Source note.** The review doc titles this ADR "dbt as Source of Truth, Cortex as Downstream" and recommends dbt MetricFlow as the single source of truth. **That option is not implementable as written and this draft departs from it deliberately:** MetricFlow requires dbt Cloud for BI integration (the platform runs dbt Core, ADR-001) and cannot feed Cortex Analyst regardless of plan tier. The platform standard since the migration is Snowflake semantic views as the metric layer, with definitional ownership fixed by ADR-018. This draft records that reality; confirm the departure explicitly at the review session. **Numbering caution:** an earlier in-repo sequence assigned 008 to the Retail Source Split; this file uses the external register's numbering per the [ADR index](README.md) collision note.

## Context

The review doc's premise was two semantic layers in active use — dbt MetricFlow YAML and Snowflake Cortex Analyst semantic model YAML — with divergence between them as the risk: a metric defined slightly differently in each produces inconsistent answers depending on whether the user goes through Power BI or Cortex Analyst, a trust-destroying outcome.

The divergence risk is real, but the layer inventory has changed since the doc was written. MetricFlow was evaluated and set aside: its BI integration requires dbt Cloud, and it cannot serve as a source for Cortex Analyst on any plan tier. The platform now operates **Snowflake semantic views** (DPR, RETAIL, and companion views, with generated DDL and a drift check — `generate_semantic_view_ddl.py --check` — in CI) as the metric layer serving both Cortex Analyst and Power BI. ADR-018 subsequently fixed where definitions live: in dbt, at or below the fact grain, with semantic views as thin exposure surfaces.

What still needs deciding here is the governance hierarchy itself, so no future tool evaluation reopens it informally.

## Decision

- **Snowflake semantic views are the platform's single metric exposure layer.** Cortex Analyst and Power BI both consume certified metrics through this layer; neither defines metrics (ADR-004).
- **Metric definitions are governed in dbt**, at or below the fact grain, per ADR-018. Semantic views expose metrics; they do not define them. A view carrying real derivation logic is a defect.
- **Semantic view DDL is generated from the repo and drift-checked in CI**, so the metric layer remains version-controlled even though it is materialized in Snowflake rather than in dbt YAML.
- **The ADR-005 gate applies to any metric entering a semantic view.** No metric may exist in a semantic view (or the Cortex semantic model) without an ADR-005 approved definition.
- **dbt MetricFlow is not used.** Any future reintroduction requires superseding this ADR, not a side adoption.

## Options considered

### Option A: Snowflake semantic views as the metric layer, definitions in dbt (selected)

Matches how the platform actually runs, keeps a single exposure layer feeding both consumers (eliminating the two-layer drift the review doc feared), and preserves the review doc's real goal — version control and the ADR-005 gate — via generated, drift-checked DDL and ADR-018 ownership rules.

### Option B: dbt MetricFlow as source of truth, Cortex YAML downstream (set aside)

The review doc's recommendation. Its genuine advantage: metric definitions in version-controlled YAML inside the dbt project, gated by ADR-005 with no generation step. Set aside as infeasible: MetricFlow's BI integration requires dbt Cloud, and MetricFlow cannot feed Cortex Analyst on any plan tier, so it cannot govern the platform's T3 surface at all.

### Option C: Cortex Analyst semantic model YAML as primary (set aside)

Its advantage: simplest path for Cortex users, proven in the POC. Set aside because a hand-maintained Snowsight artifact lives outside version control and the ADR-005 gate — the precise failure mode this ADR exists to prevent.

### Option D: Dual layers with a sprint-review sync check (set aside)

Preserves both tools' strengths. Set aside because a periodic manual sync does not prevent drift, it schedules the discovery of drift; maintenance cost is high and the trust failure can still occur between checks.

## Consequences

**Positive**
- One metric layer, two consumers: Power BI and Cortex Analyst cannot disagree by construction.
- The metric layer is version-controlled and CI-checked despite being a Snowflake-side object.
- ADR-005 and ADR-018 compose cleanly: gate on definition, define once upstream, expose thinly.

**Negative**
- The generate-and-check pipeline is real machinery the team must maintain; a broken drift check silently reopens the drift surface.
- Semantic views are a newer Snowflake feature; the platform carries some vendor-roadmap exposure on its most trust-critical layer.

**Accepted risks**
- Cross-view duplication of shared metrics remains possible until the canonical metric catalogue (ADR-018 §5 target state) lands; until then, reconciliation tests and PR review are the enforcement.

## Revisit trigger

Reopen if Snowflake materially changes semantic view capabilities or pricing, if MetricFlow gains dbt-Core BI integration and Cortex compatibility, or when the ADR-018 catalogue-and-generate mechanism lands and the generation source should be re-anchored — whichever comes first.
