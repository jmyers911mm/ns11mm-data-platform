# Architecture Decision Records

This folder contains the Architecture Decision Records (ADRs) for the NS11MM Data Platform. Each ADR documents a significant architectural or governance decision: what was decided, why, and what alternatives were considered.

ADRs are the authoritative record of why the platform is built the way it is. When you encounter a design choice that seems unusual, an ADR usually explains it.

---

## ADR index

| ADR | Title | Status |
| --- | --- | --- |
| [ADR-001](ADR_001_stack_selection.md) | Stack Selection: Snowflake, dbt Core, Power BI, and Azure | Accepted — revision in progress (Snowflake migration draft) |
| [ADR-002](ADR_002_medallion_architecture.md) | Medallion Architecture: Bronze / Silver / Gold Layers | Accepted — revision in progress (Fabric→Snowflake schema mapping) |
| [ADR-003](ADR_003_ingestion_strategy.md) | Ingestion Strategy: Custom Python Pipelines via Azure | Accepted — rewrite in progress (replaces Fabric-connector text) |
| [ADR-004](ADR_004_no_logic_in_power_bi.md) | No Business Logic in Power BI: Thin Display Layer Only | Accepted (current) |
| [ADR-005](ADR_005_metric_definition_gate.md) | Metric Definition Gate: No Gold Model Without Approved Definition | Accepted — minor revision in progress (extends gate to Cortex semantic model YAML) |
| [ADR-006](ADR_006_change_management.md) | Change Management: Seven-Stage Process | Accepted (current) |
| [ADR-007](ADR_007_bronze_immutability.md) | Bronze Layer Immutability: Standalone Rule and Exception Process | Proposed — decision pending review session |
| [ADR-008](ADR_008_semantic_layer_governance.md) | Semantic Layer Governance: Snowflake Semantic Views as the Metric Layer, Definitions Governed in dbt | Proposed — decision pending review session |
| [ADR-009](ADR_009_reporting_tiers.md) | Reporting Tiers Framework: T3 / T2 / T1 | Proposed — decision pending review session |
| [ADR-010](ADR_010_power_bi_authorization.md) | Power BI Authorization Model: Entra ID SSO, External OAuth, Per-User UPN Mapping | Proposed — decision pending review session |
| [ADR-011](ADR_011_orchestration.md) | Orchestration: Azure DevOps Scheduling, dbt Run Order, and Failure Handling | Proposed — decision pending review session |
| [ADR-012](ADR_012_data_retention_archival.md) | Data Retention and Archival: Bronze Cost and Compliance Policy | Proposed — no option selected; session decision required |
| [ADR-013](ADR_013_private_ai_workspace.md) | Private AI Workspace: Self-Hosted Inference for Sensitive Data | Proposed — decision pending review session |
| [ADR-014](ADR_014_change_validation.md) | Change Validation and Non-Regression | Proposed — decision pending review session |
| [ADR-015](ADR_015_data_monitoring.md) | Data Monitoring and Automated Validation | Proposed — decision pending review session |
| [ADR-016](ADR_016_service_level_agreements.md) | Service Level Agreements | Proposed — decision pending review session |
| [ADR-017](ADR_017_platform_audit_process.md) | Platform Audit Process | Proposed — decision pending review session |
| [ADR-018](ADR_018_metric_definition_ownership.md) | Metric Definition Ownership Across Semantic Views and Report Models | Proposed |
| [ADR-019](ADR_019_single_source_database.md) | All Environments Read Source Data from a Single Shared Database (NS11MM_DW_DEV) | Proposed |
| [ADR-020](ADR_020_materialization_policy.md) | Materialization Is Set by Layer Default, and Overridden Only for a Stated Reason | Proposed |
| [ADR-021](ADR_021_report_serving_layer.md) | Report Serving Models Are Named by Role, and Projection Chains Off a Wrapper Are Permitted | Proposed |

## Numbering

ADR-001 through ADR-021 now all live in this repository. ADR-007 through ADR-017 were adopted from the external decision register (Platform Hub) as Proposed drafts on 2026-08-05, drafted from the ADR Review working document; their decision boxes in that document were empty, so each remains **Proposed** until the Jeremy/Diana review session ratifies (or amends) it through the ADR-006 change process.


**Known open item — 007/008 register collision (owner: Jeremy).** Two numbering sequences exist for 007/008: an earlier in-repo pair (007 Drupal Ingestion Path / 008 Retail Source Split) and the external register's pair (007 Bronze Immutability / 008 Semantic-Layer Governance). The adopted files use the **external register's numbering**; the collision must be resolved before 007/008 are ratified. Until then, treat cross-references to 007/008 in older documents with care and check which sequence is meant. The Drupal Ingestion Path and Retail Source Split decisions still need numbers of their own once the collision is resolved.

## Open confirmations

ADR-001 through ADR-006 carry `[confirm]` markers on facts reconstructed from the ADR Review working document (original dates, decider lists, exact stage names, schema identifiers). These confirmation debts are tracked for committee review in 2026-08 (owner: Jeremy); do not resolve them ad hoc.

---

## How to read an ADR

Each ADR contains:

- **Status** — Proposed, Accepted, Deprecated, or Superseded
- **Context** — The problem or situation that required a decision
- **Decision** — What was decided
- **Consequences** — What this decision means going forward (tradeoffs, constraints, follow-on work)

---

## How to add an ADR

1. Copy an existing ADR as a starting point.
2. Name the file using the actual repo convention: `ADR_NNN_short_title.md` (zero-padded three-digit number, underscores — e.g. `ADR_019_fiscal_calendar.md`).
3. Take the next number from the external decision register (Platform Hub) so repo and register stay in sequence — do not reuse or guess numbers.
4. Set **Status: Proposed** and open a PR; the decision is ratified through the change-management process (ADR-006).
5. Add the new ADR to the index table above and to the ADR table in `docs/README.md`.
