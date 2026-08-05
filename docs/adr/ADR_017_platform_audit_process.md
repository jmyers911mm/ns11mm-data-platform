# ADR-017: Platform Audit Process

**Status:** Proposed (drafted from the ADR Review working document; decision pending the Jeremy/Diana review session)
**Category:** Governance
**Date:** August 5, 2026
**Deciders:** Jeremy Myers (VP AI & Analytics)
**Consulted:** Diana (Data & AI Team — gathers the audit data package); Michael Cartier (CIO — receives findings)
**Related:** ADR-005, ADR-006, ADR-014, ADR-015, ADR-016 (the audited surfaces), ADR-009 (Reporting Tiers)

> **Source note.** Drafted from the ADR Review working document (Part 2, ADR-017); decision box empty, recommended option drafted pending the session. First audit is targeted for **October 2026** — between the commemoration freeze and the December go-live, which is deliberate: it is the last full governance check before production commitments are made.

## Context

An ADR framework that is never audited is governance documentation, not governance. The audit closes the loop: are the rules in the ADRs actually being followed, is monitoring catching real issues, are SLA commitments being met, and do the ADRs themselves remain accurate? The first audit in October 2026 also gives Jeremy something concrete to present to Michael Cartier showing the governance framework is operational, not just designed — evidence that matters ahead of the December go-live decision.

## Decision

**A quarterly platform audit covering six areas**, first audit October 2026:

1. ADR lifecycle (statuses current, `[confirm]` debts and open collisions being retired, supersessions recorded)
2. Change management compliance (ADR-006: Change IDs, gate adherence, freeze compliance)
3. Monitoring and test coverage (ADR-015: required-versus-actual minimum suites, exception review)
4. SLA performance (ADR-016: windows met, incident log quality)
5. Metric registry compliance (ADR-005/ADR-018: gated definitions, reconciliation test results)
6. Access and security (ADR-010 provisioning conformance, role grants, credential hygiene)

**Roles:** Diana gathers the data package and drafts findings; Jeremy reviews and presents to Michael Cartier in the monthly stakeholder update.

**Finding classification:** Pass, Finding, or Critical Finding. **Critical Findings go to Michael Cartier within 48 hours**, regardless of the update schedule — that is the out-of-cycle escalation trigger.

## Options considered

### Option A: Quarterly, six areas (recommended)

Wins because a first-year platform accumulates drift fast — quarterly cadence catches it while it is still cheap to correct — and the six areas map one-to-one onto the governance ADRs, so the audit measures the framework rather than sampling it.

### Option B: Semi-annual (April and October) (set aside)

Its genuine advantage: half the overhead, and each audit sees a longer trend line, on a team where audit effort competes directly with build effort. Set aside because six-month gaps during the highest-volume build phase let issues accumulate and compound; the second audit would arrive after go-live commitments were already made on unverified compliance.

### Option C: Annual (set aside)

Its genuine advantage: the mature-platform steady state, minimal overhead. Set aside because it is too infrequent for a platform in its first year of production operation — an annual cycle means go-live happens with zero completed audits.

## Consequences

**Positive**
- Governance claims become evidenced: the framework is demonstrated operational to the CIO, not asserted.
- Drift in any of the six areas is surfaced within a quarter, while correction is cheap.
- The Pass/Finding/Critical taxonomy with a 48-hour escalation path means bad news travels fast by rule, not by courage.

**Negative**
- The quarterly data package is real recurring work for Diana, in tension with build and intake duties.
- Findings create obligations: an audit that surfaces issues without remediation capacity becomes a demoralizing backlog.

**Accepted risks**
- The team audits itself; independence is limited. Mitigated partially by the mechanical, evidence-based checks (coverage diffs, SLA logs) and by findings going to the CIO unfiltered.

## Revisit trigger

Reopen after two consecutive clean audits (consider relaxing to semi-annual as the platform matures), if audit effort exceeds what the team can absorb alongside SLA commitments, or if an external or institutional audit requirement arrives that this process must merge with — whichever comes first.
