# ADR-001: Stack Selection: Snowflake, dbt Core, Power BI, and Azure

- **Status:** Accepted. Revision in progress (this draft applies the Snowflake migration).
- **Category:** Foundational / Stack
- **Date:** Original [confirm]. This revision 2026-07-13.
- **Deciders:** Jeremy Myers (VP AI & Analytics); Michael Cartier (CIO, sponsor) [confirm]
- **Related:** ADR-002 (Medallion Architecture), ADR-003 (Ingestion Strategy), ADR-004 (No Business Logic in Power BI), ADR-005 (Metric Definition Gate)

> **Source note.** Reconstructed from the ADR Review working document (Part 1 status summary) plus current platform context, and rewritten to the most recent intended state. This supersedes the pre-migration text but must be reconciled against the canonical ADR-001 before it replaces it. Values marked [confirm] need to come from the source ADR or from you.

## Context

NS11MM is replacing a legacy Pentaho ETL and SSRS reporting estate with a modern data platform, on a hard deadline set by the Pentaho license lapse of January 5, 2027 and a production go-live target of December 2026. The platform was originally scoped around Microsoft Fabric. That scoping was revised: the platform now runs on Snowflake for storage and compute, dbt Core for transformation and the semantic layer, Power BI for visualization, and Azure as the cloud and DevOps plane.

This ADR records the stack decision and the rationale for the Snowflake migration. All Fabric references from the original ADR are removed.

## Decision

The certified platform stack is:

- **Snowflake** as the cloud data warehouse (account `om01578.east-us.azure.snowflakecomputing.com`, on Azure), providing separated storage and compute.
- **dbt Core 1.8.4** as the sole transformation and semantic-definition layer. All business logic lives here (see ADR-004 and ADR-005).
- **Power BI** as a thin display layer only (see ADR-004).
- **Azure** as the cloud and DevOps plane: Azure DevOps for CI and orchestration, Azure Key Vault for secrets.
- **Custom Python ingestion pipelines** as the standard path into the platform, in place of native or managed connectors. The rationale and rejection of native connectors are documented in ADR-003.
- **Snowflake Cortex Analyst** as the natural-language analytics tool, positioned in the T3 reporting tier. The tier framework is formalized in ADR-009 (proposed) [confirm once ADR-009 is ratified].

## Rationale for the Snowflake migration

- Separation of storage and compute gives predictable, workload-scoped cost control; compute is the dominant cost driver (70 to 85 percent of spend), which the warehouse governance model is built around.
- dbt Core provides native version control, testing, and lineage, which the governance model (ADR-005, ADR-006) depends on and which the prior tooling could not provide.
- Cortex Analyst enables governed natural-language querying directly against the semantic layer.
- Azure alignment preserves integration with NS11MM's existing Microsoft 365 and Entra ID estate (see ADR-010 for the Power BI authorization chain).

## Consequences

- Compute cost governance becomes a first-class operational concern; warehouse sizing and auto-suspend policy matter more than storage.
- dbt Core (rather than dbt Cloud) means orchestration is owned on the Azure DevOps side; see ADR-011 (proposed).
- Custom Python ingestion carries higher build and maintenance effort than managed connectors, accepted in exchange for control over append-only landing and lineage (ADR-003, ADR-007).

## Revisions applied in this version

- Removed all Microsoft Fabric references.
- Added the rationale for the Snowflake migration.
- Documented the custom Python pipeline decision (detail in ADR-003).
- Added Cortex Analyst as the T3-tier analytics tool.