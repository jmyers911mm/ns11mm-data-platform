# ADR-005: Metric Definition Gate: No Gold Model Without Approved Definition

- **Status:** Accepted. Minor revision in progress (extends the gate to Cortex semantic model YAML).
- **Category:** Governance / Metrics
- **Date:** Original [confirm]. This revision 2026-07-13.
- **Deciders:** Jeremy Myers (VP AI & Analytics)
- **Related:** ADR-002 (Medallion Architecture), ADR-004 (No Business Logic in Power BI)

> **Source note.** Reconstructed from the ADR Review working document plus platform context, with the single required revision applied. Reconcile against the canonical ADR-005 before replacing it. Note the numbering overlap flagged separately: the metric-ownership rules drafted earlier (definition vs exposure across semantic views and `rpt_` tables) sit against this ADR and ADR-008 rather than as a new number.

## Context

A certified metric must have an approved definition before any engineering that depends on it is built. This gate is what keeps the platform's metrics trustworthy: definition precedes construction, so a Gold model is never shipped around a metric whose meaning was never agreed.

The platform now exposes metrics through two semantic surfaces: the dbt semantic layer and the Snowflake Cortex Analyst semantic model (YAML). The gate must apply to both, or a metric could enter Cortex YAML without ever passing the definition gate.

## Decision

- **No Gold model is built without an approved metric definition.** The definition (population, measure, business rule) is agreed and recorded before the dependent `dim_`, `fct_`, `rpt_`, or semantic artifact is engineered.
- **The gate now extends explicitly to the Snowflake Cortex Analyst semantic model YAML.** No metric may exist in Cortex YAML that does not have an ADR-005 approved definition. This is consistent with the hierarchy in ADR-008 (proposed): dbt is the source of truth, Cortex is a downstream artifact.
- The gate fires on **new definitions**, not on new consumers of existing definitions. Reusing an already-certified metric at a new grain or in a new report does not re-trigger the gate.

## Consequences

- Metric meaning is settled before build, not discovered in review.
- Cortex YAML changes that introduce a metric are governed exactly as dbt metric changes are.
- Reuse stays cheap: exposing an existing metric is not gated, which keeps the rule from taxing routine report work.

## Revisions applied in this version

- Added one clause extending the gate to the Snowflake Cortex Analyst semantic model YAML.

## Open item

The definition-versus-exposure rules drafted separately (a metric is defined once upstream and only exposed by semantic views and `rpt_` tables, with reconciliation testing) refine this ADR and ADR-008. Decide whether they fold into ADR-005/ADR-008 or stand as their own ratified ADR, and assign the correct number rather than the provisional one used in that draft. [confirm]