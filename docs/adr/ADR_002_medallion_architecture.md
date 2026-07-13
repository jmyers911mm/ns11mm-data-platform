# ADR-002: Medallion Architecture: Bronze / Silver / Gold Layers

- **Status:** Accepted. Revision in progress (this draft maps Fabric schemas to Snowflake).
- **Category:** Architecture
- **Date:** Original [confirm]. This revision 2026-07-13.
- **Deciders:** Jeremy Myers (VP AI & Analytics)
- **Related:** ADR-001 (Stack Selection), ADR-003 (Ingestion Strategy), ADR-007 (Bronze Immutability, proposed), ADR-005 (Metric Definition Gate)

> **Source note.** Reconstructed from the ADR Review working document (Part 1 status summary) plus current platform context, and rewritten to the most recent intended state. Reconcile against the canonical ADR-002 before replacing it. The Bronze/Silver/Gold to RAW/INTERMEDIATE/MARTS mapping below reflects the current repo layout; confirm the exact schema names against `NS11MM_DW_*` before publishing.

## Context

The platform organizes data in a three-tier medallion architecture. The original ADR described these tiers as Microsoft Fabric lakehouse layers. This revision replaces the Fabric lakehouse schema references with their Snowflake schema equivalents and records Cortex Analyst as a Gold-layer consumer.

## Decision

Data flows through three governed layers, implemented as Snowflake schemas:

- **Bronze (RAW):** immutable landing zone, append-only and write-once. Source data lands here unchanged. Immutability is owned as a standalone decision in ADR-007 (proposed). RAW is materialized as transient tables to avoid Fail-safe overhead, consistent with the compute-dominant cost model.
- **Silver (INTERMEDIATE):** cleansed and conformed. Staging models (`stg_<source>__<entity>`) resolve into intermediate models (`int_<domain>__<entity>`).
- **Gold (MARTS):** business-facing dimensions, facts, and report models (`dim_`, `fct_`, `rpt_`), plus the certified semantic layer. Supplementary schemas: `SEEDS` (reference seeds) and `ML_FEATURES`.

**Gold-layer consumers** are Power BI (thin display, ADR-004) and Snowflake Cortex Analyst (natural-language querying). Both read certified Gold artifacts; neither introduces business logic.

Confirm exact Snowflake schema identifiers [confirm]: the dev database is `NS11MM_DW_DEV_JMYERS`; production schema names should be listed here explicitly.

## Consequences

- The layer boundary is a governance boundary: no business logic upstream of Silver, no re-derivation of certified metrics downstream of Gold.
- RAW immutability (ADR-007) constrains ingestion design (ADR-003): connectors with merge semantics require the Streams CDC workaround rather than in-place updates to RAW.
- Adding Cortex Analyst as a Gold consumer brings it under the same certification and metric-gate rules as Power BI (ADR-005, ADR-008 proposed).

## Revisions applied in this version

- Replaced Fabric lakehouse schema references with Snowflake schema equivalents.
- Added Cortex Analyst as a Gold-layer consumer.