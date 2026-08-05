# ADR-015: Data Monitoring and Automated Validation

**Status:** Proposed (drafted from the ADR Review working document; decision pending the Jeremy/Diana review session)
**Category:** Operations
**Date:** August 5, 2026
**Deciders:** Jeremy Myers (VP AI & Analytics)
**Consulted:** Diana (Data & AI Team)
**Related:** ADR-014 (Change Validation — tests are the regression detection mechanism), ADR-016 (SLAs — monitoring thresholds must support SLA response windows), ADR-002 (Medallion Architecture), ADR-006 (Change Management — freeze protocols)

> **Source note.** Drafted from the ADR Review working document (Part 2, ADR-015); decision box empty, recommended option drafted pending the session. The repo already carries a substantial dbt test suite; this ADR converts "tests exist" into "these tests are the enforced minimum per model type." Reconcile the minimum suite below against the existing test coverage and the severity conventions in use before ratification [confirm].

## Context

Every layer of the platform needs automated tests that run on every pipeline execution and every CI build. Without this, data issues propagate silently through Bronze and Silver before surfacing as wrong numbers in a stakeholder report. The question is not whether to have monitoring — that is settled, and a large test suite already runs in CI — but what the minimum requirements are per model type, how alerts are routed, and how exceptions are governed.

## Decision

**A mandatory minimum test suite applies per model type, enforced by CI. A model that does not meet its minimum does not ship.**

- **Bronze (RAW):** freshness, row-count plausibility, and required-field null checks.
- **Silver (staging `stg_`, intermediate `int_`):** the Bronze set plus referential integrity and accepted-values checks; primary-key uniqueness declared and tested on every model that states a grain.
- **Gold (`dim_`, `fct_`, `rpt_`, semantic layer):** the Silver set plus metric drift detection, ADR-018 reconciliation tests for shared metrics, and the `is_commemoration_day` flag test in the date dimension.
- **Alert routing:** alerts route to the on-duty engineer with severity-based escalation to Jeremy. During the September 6–16 commemoration freeze, alerts are muted per ADR-006 freeze protocol. [confirm routing channel and severity thresholds]
- **Exceptions:** a model may be granted a documented monitoring exception (recorded in its schema.yml with a reason and an expiry); exceptions are reviewed at each ADR-017 audit. Undocumented gaps are findings.

## Options considered

### Option A: Minimum suite per model type, CI-enforced (recommended)

Wins because it catches issues at the earliest layer they can be detected (freshness and volume anomalies stop bad data before it propagates), it is checkable by machine rather than by review vigilance, and per-model-type minimums scale automatically as models are added.

### Option B: Minimum suite for Gold only (set aside)

Its genuine advantage: lowest overhead, and it concentrates effort on the layer stakeholders actually see. Set aside because detection at the last layer means the issue has already propagated — diagnosis must then walk backward through untested layers, and the same root cause pollutes every Gold consumer before it is caught.

### Option C: Requirements per source system rather than per model type (set aside)

Its genuine advantage: sources genuinely differ (a ticketing feed and a marketing feed do not warrant identical scrutiny), so tailoring avoids both over- and under-testing. Set aside because per-source rules create N test standards to maintain and audit, and layer position — not source identity — is what determines a test's detection value.

## Consequences

**Positive**
- Data issues are detected at the layer where they enter, not in a stakeholder meeting.
- ADR-014's non-regression claims have a technical mechanism behind them.
- Coverage becomes auditable: the ADR-017 audit can diff required-versus-actual tests mechanically.

**Negative**
- CI runtime and Snowflake compute cost grow with the test surface; the minimum suite is a floor that every new model must pay for.
- Plausibility and drift thresholds require tuning; badly tuned thresholds either alarm constantly (and get ignored) or never fire.

**Accepted risks**
- Alert fatigue is the standing failure mode of monitoring systems; the exception process and threshold reviews at each audit are the mitigation, not a guarantee.

## Revisit trigger

Reopen if alert volume exceeds what the on-duty rotation can triage within ADR-016 response windows for a sustained period, if the CI test runtime materially delays merges, or at the first ADR-017 audit (October 2026) with a quarter of signal data — whichever comes first.
