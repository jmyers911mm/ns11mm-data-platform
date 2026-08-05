# ADR-009: Reporting Tiers Framework: T3 / T2 / T1

**Status:** Proposed (drafted from the ADR Review working document; decision pending the Jeremy/Diana review session)
**Category:** Governance
**Date:** August 5, 2026
**Deciders:** Jeremy Myers (VP AI & Analytics)
**Consulted:** Diana (Data & AI Team) — operates the intake this framework governs
**Related:** ADR-008 (Semantic Layer Governance), ADR-006 (Change Management), ADR-016 (SLAs)

> **Source note.** Drafted from the ADR Review working document (Part 2, ADR-009); decision box empty, recommended option drafted pending the session. Cortex Analyst as the T3 tool is already recorded in ADR-001.

## Context

The three-tier reporting model — T3: Cortex Analyst self-service, T2: certified Power BI dashboards, T1: scheduled operational reports — is the framework Diana uses to route every incoming report request. Without a formal ADR, tier assignment is informal and inconsistent: domain owners will not understand why some requests become Power BI reports while others are handled via Cortex, and the team relitigates the decision for every request.

Stakeholder intake is beginning, which is the P2 urgency in the review doc: the framework must exist before the request volume does.

## Decision

The three tiers are defined as follows, and **T3 is the default for all new requests**:

- **T3 — Cortex Analyst self-service.** Ad hoc and exploratory questions answered through the semantic layer (ADR-008). Default routing for every request that does not justify escalation.
- **T2 — Certified Power BI dashboards.** Recurring certified views that Cortex cannot reliably serve: complex multi-domain joins, executive distribution requirements. Requires domain-owner justification for escalation above T3.
- **T1 — Scheduled operational reports.** Reserved for board-level or regulatory reports with a defined schedule.

A request arriving without a specified tier is assessed against T3 first; the burden of justification sits with escalation, not with self-service. Tier assignment is recorded at intake so the decision is auditable and not relitigated. Delivery commitments per tier are set in ADR-016 (proposed).

## Options considered

### Option A: T3 default, justified escalation (recommended)

Wins because it routes demand toward the cheapest, fastest surface, caps Power BI proliferation (each T2 report is a maintenance liability under ADR-004's thin-display rule), and gives Diana a defensible default instead of a per-request negotiation.

### Option B: T2 (Power BI) default, T3 opt-in (set aside)

Its genuine advantage: Power BI is what existing stakeholders know, so adoption friction is lower and trust in the new platform builds on familiar ground. Set aside because it recreates the report-estate proliferation the platform is retiring — every request becoming a dashboard is precisely the SSRS failure mode — and it under-uses the T3 investment.

### Option C: No default; Jeremy assesses each request (set aside)

Maximum flexibility and a consistent single judge. Set aside because it does not reduce Diana's decision overhead (every request still queues on one person), does not scale with intake volume, and leaves domain owners with no predictable rule to plan against.

## Consequences

**Positive**
- Every request has a predictable routing rule; tier debates happen once, at the framework level.
- Power BI estate growth is bounded by a justification gate rather than by demand.
- SLAs (ADR-016) can attach delivery commitments to tiers instead of to individual reports.

**Negative**
- Stakeholders accustomed to receiving dashboards must be told "no, use Cortex" — a change-management cost paid by Diana and Jeremy in the first months.
- T3-by-default only holds if Cortex answer quality stays high; a bad early answer pushes users to demand T2 escalation.

**Accepted risks**
- Escalation criteria ("complex multi-domain joins", "executive distribution") involve judgment; borderline cases will still reach Jeremy until precedent accumulates.

## Revisit trigger

Reopen if T2 escalation requests exceed roughly half of intake over a quarter (the default is being overridden in practice), if Cortex Analyst answer-quality metrics fall below the trust bar during the October 2026 audit (ADR-017), or at the December 2026 go-live review — whichever comes first.
