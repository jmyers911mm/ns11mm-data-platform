# ADR-016: Service Level Agreements

**Status:** Proposed (drafted from the ADR Review working document; decision pending the Jeremy/Diana review session)
**Category:** Operations
**Date:** August 5, 2026
**Deciders:** Jeremy Myers (VP AI & Analytics)
**Consulted:** Diana (Data & AI Team — maintains the incident log); Michael Cartier (CIO — receives SLA reporting)
**Related:** ADR-015 (Monitoring — thresholds must support the response windows), ADR-017 (Audit — measures SLA performance), ADR-009 (Reporting Tiers), ADR-006 (Change Management — freeze windows)

> **Source note.** Drafted from the ADR Review working document (Part 2, ADR-016); decision box empty, recommended option drafted pending the session. Per-source freshness commitments are placeholders until each source's pipeline cadence is fixed under ADR-011 [confirm per-source freshness table before ratification]. Note the review doc tightens SLAs for **September 8–13**, inside the September 6–16 change freeze (ADR-006): the freeze pauses change, not operations — both apply simultaneously.

## Context

The team makes implicit commitments every time a domain owner asks when their data will be ready or how long a report request will take. Unstated commitments make every missed expectation a surprise and leave the team with no basis for managing stakeholder expectations — or for saying no. The SLA structure must also survive the September 11 anniversary window, which imposes tighter timing requirements than normal operations, and it must be measurable so the ADR-017 audit and the quarterly report to Michael Cartier have something to measure.

## Decision

**A three-tier SLA structure covering pipeline freshness, incident response, and report delivery:**

- **Pipeline freshness:** source-specific commitments anchored to business-day start, recorded per source in this ADR's appendix as pipelines onboard. [confirm per-source table]
- **Incident response** (acknowledge / assess / resolve): Critical — 1 / 2 / 4 hours; High — 4 / 8 / 24 hours; Normal — 24 / 48 hours / 5 business days.
- **Report delivery** by reporting tier (ADR-009): T3 — 5 days; T2 — 10 to 20 days; T1 — 15 days.
- **Anniversary window:** September 8–13, Critical and High windows tighten by 50%. This operates inside the September 6–16 change freeze (ADR-006): changes pause, operational response does not.
- **Reporting:** SLA performance is reported to Michael Cartier quarterly; Diana maintains the incident log the reporting draws from.

## Options considered

### Option A: Three-tier structure with specific windows (recommended)

Wins because it gives stakeholders numbers they can plan against, gives the team a defensible basis for triage ("this is Normal, not Critical"), and produces exactly the measurement surface the audit and the quarterly CIO report need.

### Option B: Two-tier structure (critical / normal) with fewer commitments (set aside)

Its genuine advantage: easier to maintain and harder to miss — fewer promises means fewer breaches, sensible for a small team's first SLA. Set aside because the middle band is where most real incidents land; with only two tiers, everything urgent-but-not-catastrophic either inflates to Critical (burning out the response capacity) or deflates to Normal (disappointing stakeholders).

### Option C: SLAs per domain rather than per tier (set aside)

Its genuine advantage: domains genuinely differ — attendance is more time-sensitive than marketing analytics — so tailoring matches commitment to need. Set aside because six domains means six SLA sets to negotiate, track, and audit; the domain-sensitivity difference is better expressed by assigning each domain's pipelines and incidents to the right tier within one structure.

## Consequences

**Positive**
- Expectations are managed by a published rule, not by per-request negotiation; misses are visible and countable rather than anecdotal.
- The quarterly report gives Michael Cartier governance evidence, and the audit (ADR-017) a compliance measure.
- Triage decisions gain a shared vocabulary across the team and stakeholders.

**Negative**
- Every window is now a promise the team can publicly miss; the incident log is permanent evidence of performance either way.
- Maintaining the per-source freshness appendix and incident log is standing work assigned to Diana.

**Accepted risks**
- The response windows assume current staffing; a single absence during the anniversary window makes the tightened Critical commitment (30 minutes to acknowledge) fragile. [confirm the anniversary-window on-call plan]

## Revisit trigger

Reopen after the first anniversary window operating under these SLAs (September 2026 retrospective), if two consecutive quarterly reports show a tier consistently missed or trivially met (windows miscalibrated), or when headcount or pipeline volume changes materially — whichever comes first.
