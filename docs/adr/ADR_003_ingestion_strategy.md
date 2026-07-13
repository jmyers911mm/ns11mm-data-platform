# ADR-003: Ingestion Strategy: Custom Python Pipelines via Azure

- **Status:** Accepted. Rewrite in progress (this draft replaces the Fabric-connector text).
- **Category:** Ingestion
- **Date:** Original [confirm]. This rewrite 2026-07-13.
- **Deciders:** Jeremy Myers (VP AI & Analytics)
- **Related:** ADR-001 (Stack Selection), ADR-002 (Medallion Architecture), ADR-007 (Bronze Immutability, proposed), ADR-011 (Orchestration, proposed)

> **Source note.** The review doc flags this ADR for a full rewrite because the canonical text still describes Fabric native connectors as the primary path. This draft documents the current standard (custom Python) and the connector rejection rationale, reconstructed from the review doc plus platform context. Reconcile against the canonical ADR-003 and confirm per-source specifics before publishing.

## Context

Ingestion into the platform was originally specified around Fabric native connectors. That path is rejected. The standard is now custom Python ingestion pipelines running on Azure, landing data append-only into the Bronze (RAW) layer.

The driving constraint is Bronze immutability (ADR-002, and owned as a standalone rule in ADR-007). Many native and managed connectors use merge or upsert semantics, which overwrite landed rows and destroy the append-only guarantee that protects audit and lineage integrity. Custom pipelines give full control over landing format, load metadata, and append-only behavior.

## Decision

- **Custom Python ingestion pipelines are the standard path to Bronze.** Each source is ingested by a controlled pipeline that writes append-only into RAW.
- **Native and managed connectors are rejected as the primary path.** A source may use a native connector only through the formal exception process defined in ADR-007 (proposed).
- **Snowflake Streams CDC is the approved workaround** for sources whose upstream only exposes merge or change-data semantics, so that change capture happens without violating RAW append-only.
- **Secrets** (source credentials, keys, tokens) live in Azure Key Vault (`kv-ns11mm-dp-dev` in dev) and never in code or YAML, per the platform hard gates.
- **On-premises SQL Server sources** (Gateway/Galaxy1, NCR CounterPoint) use the two-hop pattern: VM-side `bcp` export, RDP file transfer, then workstation `PUT` and `COPY INTO` Snowflake. Real table names and schema are confirmed with the source-system owner before build [confirm: Kenny Yeung schema confirmation].

## Connector rejection rationale

- Merge/upsert semantics overwrite RAW rows, breaking append-only immutability and the lineage/audit guarantees that depend on it.
- Native connectors abstract away landing behavior, removing the control needed to enforce write-once and to attach load metadata.
- Custom pipelines make the ingestion contract explicit and testable, which the change-management and monitoring ADRs (ADR-006, ADR-015 proposed) rely on.

## Consequences

- Higher build and maintenance effort per source, accepted in exchange for immutability, control, and lineage.
- Orchestration of these pipelines is owned on the Azure DevOps side (ADR-011 proposed).
- Any request to use a native connector becomes an explicit, logged exception rather than a silent default.

## Revisions applied in this version

- Rewritten entirely.
- Documented custom Python pipelines as the standard path.
- Explained the connector rejection rationale and the Streams CDC workaround.