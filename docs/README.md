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
| **Analyst / report builder** | [Business Start Here](business/README.md) → then [Metric Glossary](business/METRIC_GLOSSARY.md) | Certified metric definitions, the report finder, and the semantic layer that powers self-service |
| **New team member (data team)** | [Onboarding](ONBOARDING.md) | Day-1 setup: clone, configure your workspace, run your first build |
| **Data engineer / contributor** | [Main README](../README.md) → [CONTRIBUTING](../CONTRIBUTING.md) | Architecture, lineage, models, tests, and the full contribution workflow |
| **On-call / responding to an incident** | [RUNBOOK](../RUNBOOK.md) | Scheduled jobs, freshness behavior, pipeline failure response, escalation |
| **Anyone making an architecture or governance decision** | [ADR Log](adr/) | Why the platform is built the way it is, decision by decision |

---

## The two homes for documentation

Documentation lives in **two** places. This map links across both so you never have to guess.

### 1. This GitHub repository (`ns11mm/ns11mm-data-platform`)

The **technical source of truth** — the dbt project, its tests, lineage, and the docs that engineers and analysts need to build and maintain it.

| Document | Audience | Purpose |
| --- | --- | --- |
| [README](../README.md) | Engineers, analysts | Architecture, data layers, models, lineage, testing strategy |
| [CONTRIBUTING](../CONTRIBUTING.md) | Contributors | Branch strategy, sandbox isolation, change gates, PR checklist, VQR workflow |
| [ONBOARDING](ONBOARDING.md) | New team members | Linear day-1 setup checklist |
| [RUNBOOK](../RUNBOOK.md) | On-call, operators | Operational procedures, incidents, pipeline failures |
| [SQL Style Guide](architecture/SQL_STYLE_GUIDE.md) | Contributors | Naming, layering, and formatting conventions |
| [Data Classification](architecture/DATA_CLASSIFICATION.md) | Everyone touching data | PII handling, classification tiers, access rules |
| [ADR Log](adr/) | Decision-makers | Architecture Decision Records |
| [Business Start Here](business/README.md) | Business users | Plain-language entry point |
| [Metric Glossary](business/METRIC_GLOSSARY.md) | Business users, analysts | What every metric means, in plain English |
| [CHANGELOG](../CHANGELOG.md) | Everyone | Release history with model/test counts |

#### Architecture and technical reference (`docs/architecture/`)

| Document | Purpose |
| --- | --- |
| [PROJECT_MAP](architecture/PROJECT_MAP.md) | Team orientation: mental model, file placement, cross-references |
| [ARCHITECTURE_FLOW](architecture/ARCHITECTURE_FLOW.md) | End-to-end data flow from source systems to Power BI |
| [SOURCE_INTEGRATION](architecture/SOURCE_INTEGRATION.md) | Per-source API profiles, auth models, extraction details for all 14 sources |
| [TEST_ORCHESTRATION](architecture/TEST_ORCHESTRATION.md) | Test scheduling, gate sequence, freshness SLAs, alert routing |
| [SNOWFLAKE_SETTINGS](../SNOWFLAKE_SETTINGS.md) | Account settings: roles, warehouses, integrations |
| [USAGE_AUDIT](architecture/USAGE_AUDIT.md) | Credit monitoring, pipeline log queries, Cortex observability |
| [GATEWAY_COUNTERPOINT_SCHEMA_REQUEST](architecture/GATEWAY_COUNTERPOINT_SCHEMA_REQUEST.md) | Schema confirmation request for Kenny (IT) |
| [DATA_CLASSIFICATION](architecture/DATA_CLASSIFICATION.md) | PII field inventory, access tiers, masking rules |

#### ADR log (`docs/adr/`)

| ADR | Decision |
| --- | --- |
| [ADR-005](adr/0005-metric-definition-gate.md) | Metric definition gate — required before any Gold model build |
| [ADR-006](adr/0006-change-management-tiers.md) | Change management tiers (Tier 1 / Tier 2 / Emergency) |
| [ADR-007](adr/0007-drupal-ingestion-path.md) | Drupal ingestion path — **decision required** |
| [ADR-008](adr/0008-retail-source-split.md) | Retail source split (CounterPoint vs Shopify) — **decision required** |

### 2. The Platform Hub

The Platform Hub is the operational frontend for the data platform — report registry, ADR browser, onboarding tools, and the AI Digest. It is separate from GitHub and does not require technical access.

---

## Schema naming reference


| Layer | Schema in Snowflake | dbt folder | Materialization |
| --- | --- | --- | --- |
| Raw ingestion | `RAW` | (pipelines, not dbt) | Append-only tables |
| Staging | `STAGING` | `models/raw/` | Views |
| Silver / Intermediate | `INTERMEDIATE` | `models/intermediate/` | Incremental (merge) |
| Gold (dims, facts, reports) | `MARTS` | `models/marts/` | Table / Incremental |
| ML Features | `ML_FEATURES` | `models/ml_features/` | Table |
| Monitoring | `MONITORING` | (not dbt-managed) | Alerts, tasks, views |

---

## Quick links

- **Start building:** [CONTRIBUTING](../CONTRIBUTING.md)
- **Day-1 setup:** [ONBOARDING](ONBOARDING.md)
- **Something broken?** [RUNBOOK](../RUNBOOK.md)
- **What does this metric mean?** [METRIC_GLOSSARY](business/METRIC_GLOSSARY.md)
- **Where does my new file go?** [PROJECT_MAP](architecture/PROJECT_MAP.md)
