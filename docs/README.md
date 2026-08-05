# Documentation Map

> **Current scope (July 2026):** only the Gateway (ticketing) and CounterPoint (retail POS)
> sources are connected, feeding the Daily Performance Report. Other sources, models, and
> domains described below are part of the target design but are currently `enabled=false` /
> not yet ingested. See the `models/*/README.md` files for the exact enabled-vs-disabled list.

This is the front door for **all** documentation about the NS11MM Data Platform. It exists so that anyone — a board member, a marketing manager, an analyst, or a data engineer — can find what they need in under a minute.

If you only read one thing, read the row in the table below that matches who you are.

---

## Start here — pick your role

| I am a… | Start here | What you'll find |
| --- | --- | --- |
| **Business user / stakeholder** (Development, Membership, Marketing, Operations, Education, Finance) | [Business Start Here](business/README.md) | What the platform does, which dashboard answers your question, what each metric means, and who to ask |
| **Analyst / report builder** | [Business Start Here](business/README.md) → then [Building Reports & Metrics](architecture/BUILD_DIMS_METS.md) | How metrics are defined and governed; the semantic views in `cortex_project/` are the certified source of truth for metric definitions |
| **New team member (data team)** | [Onboarding](ONBOARDING.md) | Day-1 setup: clone, configure your workspace, run your first build |
| **Data engineer / contributor** | [Main README](../README.md) → [CONTRIBUTING](../CONTRIBUTING.md) | Architecture, lineage, models, tests, and the full contribution workflow |
| **On-call / responding to an incident** | [Test Orchestration](architecture/TEST_ORCHESTRATION.md) + [Usage Audit](architecture/USAGE_AUDIT.md) | Test/freshness behavior, alert routing, monitoring queries; incident write-ups live in [docs/dqi/](dqi/) |
| **Anyone making an architecture or governance decision** | [ADR Log](adr/) | Why the platform is built the way it is, decision by decision |

---

## The two homes for documentation

Documentation lives in **two** places. This map links across both so you never have to guess.

### 1. This GitHub repository (`ns11mm/ns11mm-data-platform`)

The **technical source of truth** — the dbt project, its tests, lineage, and the docs that engineers and analysts need to build and maintain it.

| Document | Audience | Purpose |
| --- | --- | --- |
| [README](../README.md) | Engineers, analysts | Architecture, data layers, models, lineage, testing strategy |
| [CONTRIBUTING](../CONTRIBUTING.md) | Contributors | Branch strategy, sandbox isolation, change gates, PR checklist |
| [ONBOARDING](ONBOARDING.md) | New team members | Linear day-1 setup checklist |
| [Building Reports & Metrics](architecture/BUILD_DIMS_METS.md) | Analysts, contributors | How to add reports, semantic views, and metrics under ADR-005/ADR-018 |
| [SQL Style Guide](architecture/SQL_STYLE_GUIDE.md) | Contributors | Naming, layering, and formatting conventions |
| [Data Classification](architecture/DATA_CLASSIFICATION.md) | Everyone touching data | PII handling, classification tiers, access rules |
| [ADR Log](adr/) | Decision-makers | Architecture Decision Records |
| [Business Start Here](business/README.md) | Business users | Plain-language entry point |
| [Data Quality Incidents](dqi/) | Everyone | Logged data-quality incidents (DQI records) |
| [POC Migration Record](POC_MIGRATION_RECORD.md) | Engineers | Historical record of the POC→production migration inventory |
| [CHANGELOG](../CHANGELOG.md) | Everyone | Release history with model/test counts |

#### Architecture and technical reference (`docs/architecture/`)

| Document | Purpose |
| --- | --- |
| [PROJECT_MAP](architecture/PROJECT_MAP.md) | Team orientation: mental model, file placement, cross-references |
| [ARCHITECTURE_FLOW](architecture/ARCHITECTURE_FLOW.md) | End-to-end data flow from source systems to Power BI |
| [SOURCE_INTEGRATION](architecture/SOURCE_INTEGRATION.md) | Per-source API profiles, auth models, extraction details |
| [TEST_ORCHESTRATION](architecture/TEST_ORCHESTRATION.md) | Test scheduling, gate sequence, freshness SLAs, alert routing |
| [SNOWFLAKE_SETTINGS](architecture/SNOWFLAKE_SETTINGS.md) | Account settings: roles, warehouses, integrations |
| [USAGE_AUDIT](architecture/USAGE_AUDIT.md) | Credit monitoring, pipeline log queries, Cortex observability |
| [DATA_CLASSIFICATION](architecture/DATA_CLASSIFICATION.md) | PII field inventory, access tiers, masking rules |

#### ADR log (`docs/adr/`)

ADR-001 through ADR-019 live in-repo. ADR-007–017 were adopted from the external decision register (Platform Hub) as **proposed** drafts on 2026-08-05, pending the ADR review session. See the [ADR index](adr/README.md) for numbering notes, including the 007/008 register collision.

| ADR | Decision |
| --- | --- |
| [ADR-001](adr/ADR_001_stack_selection.md) | Stack selection — Snowflake, dbt Core, Power BI, Azure |
| [ADR-002](adr/ADR_002_medallion_architecture.md) | Medallion architecture — Bronze / Silver / Gold layers |
| [ADR-003](adr/ADR_003_ingestion_strategy.md) | Ingestion strategy — custom Python pipelines via Azure |
| [ADR-004](adr/ADR_004_no_logic_in_power_bi.md) | No business logic in Power BI — thin display layer only |
| [ADR-005](adr/ADR_005_metric_definition_gate.md) | Metric definition gate — required before any Gold model build |
| [ADR-006](adr/ADR_006_change_management.md) | Change management — seven-stage process |
| [ADR-007](adr/ADR_007_bronze_immutability.md) | Bronze layer immutability — standalone rule and exception process — **proposed** |
| [ADR-008](adr/ADR_008_semantic_layer_governance.md) | Semantic layer governance — Snowflake semantic views as the metric layer — **proposed** |
| [ADR-009](adr/ADR_009_reporting_tiers.md) | Reporting tiers framework — T3 / T2 / T1 — **proposed** |
| [ADR-010](adr/ADR_010_power_bi_authorization.md) | Power BI authorization — Entra ID SSO, external OAuth, per-user UPN — **proposed** |
| [ADR-011](adr/ADR_011_orchestration.md) | Orchestration — Azure DevOps scheduling, dbt run order, failure handling — **proposed** |
| [ADR-012](adr/ADR_012_data_retention_archival.md) | Data retention and archival — Bronze cost and compliance policy — **proposed, no option selected** |
| [ADR-013](adr/ADR_013_private_ai_workspace.md) | Private AI workspace — self-hosted inference for sensitive data — **proposed** |
| [ADR-014](adr/ADR_014_change_validation.md) | Change validation and non-regression — **proposed** |
| [ADR-015](adr/ADR_015_data_monitoring.md) | Data monitoring and automated validation — **proposed** |
| [ADR-016](adr/ADR_016_service_level_agreements.md) | Service level agreements — **proposed** |
| [ADR-017](adr/ADR_017_platform_audit_process.md) | Platform audit process — **proposed** |
| [ADR-018](adr/ADR_018_metric_definition_ownership.md) | Metric definition ownership across semantic views and report models — **proposed** |
| [ADR-019](adr/ADR_019_single_source_database.md) | All environments read source data from a single shared database (NS11MM_DW_DEV) — **proposed** |

### 2. The Platform Hub

The Platform Hub is the operational frontend for the data platform — report registry, ADR browser, onboarding tools, and the AI Digest. It is separate from GitHub and does not require technical access.

---

## Schema naming reference

| Layer | Schema in Snowflake | dbt folder | Materialization |
| --- | --- | --- | --- |
| Raw ingestion | `RAW` | (pipelines/seed loads, not dbt) | Append-only tables |
| Staging | `STAGING` | `models/raw/` | Views |
| Silver / Intermediate | `INTERMEDIATE` | `models/intermediate/` | Views (a handful of models opt into tables/incremental) |
| Gold — dimensions & facts | `MARTS` | `models/marts/dimensions/`, `models/marts/facts/` | Tables |
| Gold — reports | `MARTS` | `models/marts/reports/` | Views |
| ML Features | `ML_FEATURES` | `models/ml_features/` | Tables |
| Reference seeds | `SEEDS` | `seeds/` | Seed tables |

---

## Quick links

- **Start building:** [CONTRIBUTING](../CONTRIBUTING.md)
- **Day-1 setup:** [ONBOARDING](ONBOARDING.md)
- **Something broken?** [TEST_ORCHESTRATION](architecture/TEST_ORCHESTRATION.md) (freshness/alerts) · [Data Quality Incidents](dqi/)
- **What does this metric mean?** [Building Reports & Metrics](architecture/BUILD_DIMS_METS.md) + the semantic view specs in `cortex_project/`
- **Where does my new file go?** [PROJECT_MAP](architecture/PROJECT_MAP.md)
