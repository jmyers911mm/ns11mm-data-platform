# ADR-004: No Business Logic in Power BI: Thin Display Layer Only

- **Status:** Accepted (current). No revision required.
- **Category:** Governance / Visualization
- **Date:** Original [confirm].
- **Deciders:** Jeremy Myers (VP AI & Analytics)
- **Related:** ADR-005 (Metric Definition Gate), ADR-002 (Medallion Architecture)

> **Source note.** The review doc marks this ADR active and stack-agnostic, requiring no changes. This file is a markdown rendering of that current decision reconstructed from platform context; reconcile against the canonical ADR-004 before replacing it.

## Context

Power BI is the platform's visualization layer. To keep a single trusted source of truth, business logic must not live in the display tool. If metrics were defined in Power BI (DAX measures encoding business rules) as well as in dbt, the two would diverge and the platform would reproduce the fragmentation of the legacy SSRS estate it is replacing.

## Decision

Power BI is a **thin display layer only**.

- All certified metrics are defined in the dbt semantic layer (ADR-005). Power BI renders them; it does not compute them.
- Power BI must not contain business logic: no DAX measures or calculated columns that encode metric populations, business rules, or derivations that belong upstream.
- Security logic does not live in Power BI either. Row-level security is enforced in Snowflake, not as Power BI DAX (see ADR-010, proposed).

## Consequences

- Metrics are consistent across every consumer, whether reached through Power BI or Cortex Analyst.
- Report authors are constrained to presentation concerns (layout, formatting, interactivity), which is the intended boundary.
- Any logic found in a Power BI report is a defect to be pushed upstream into dbt, not maintained in place.

## Revisions applied in this version

- None. The decision is current and stack-agnostic. Recorded here for completeness alongside the migrated ADRs.