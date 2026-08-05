# ADR-014: Change Validation and Non-Regression

**Status:** Proposed (drafted from the ADR Review working document; decision pending the Jeremy/Diana review session)
**Category:** Governance
**Date:** August 5, 2026
**Deciders:** Jeremy Myers (VP AI & Analytics)
**Consulted:** Diana, Kalea Ramsey (Data & AI Team — PR review co-owner)
**Related:** ADR-006 (Change Management — extends Stage 5 PR Review and Stage 6 UAT), ADR-015 (Monitoring — the technical detection mechanism), ADR-018 (Metric Definition Ownership — reconciliation tests)

> **Source note.** Drafted from the ADR Review working document (Part 2, ADR-014); decision box empty, recommended option drafted pending the session. ADR-006 carries a placeholder forward-reference to this ADR to be resolved on ratification. The change-tier names (Tier 1 through Tier 4) are the ADR-006 change tiers [confirm exact tier definitions against canonical ADR-006].

## Context

ADR-006 defines how changes are approved and deployed but says nothing about how to confirm a change actually worked, or that it did not break anything outside its stated scope. Silent regressions — a change to one model quietly altering a downstream report a stakeholder depends on — are the most common and most trust-damaging failure mode in data platforms.

The platform already has partial machinery: the dbt test suite runs in CI, and ADR-018 mandates reconciliation tests for shared metrics. What is missing is the governance requirement that ties them together: proof of goal, proof of no side effects, per change.

## Decision

**Every change must demonstrate two things before merge: it achieved its stated goal, and every object outside its stated scope is unchanged.**

- **Mandatory PR artifact:** a completed non-regression checklist with pre/post comparison evidence. Tier 1 and Tier 2 changes cannot merge without it. Tier 3 and Tier 4 changes require it for any change touching a Gold model or a Power BI dataset.
- **Scope amendment process:** when testing reveals an unexpected downstream effect, the change's stated scope is formally amended and the affected objects enter the comparison set — the effect is never waved through as incidental.
- **Deploying without the checklist, or causing an undocumented regression, is a data quality incident** (logged as a DQI), not a normal side effect.
- Detection machinery: dbt tests and ADR-018 reconciliation tests in CI (ADR-015) are the technical mechanism backing the checklist's claims.

## Options considered

### Option A: Hard requirement with mandatory PR checklist (recommended)

Wins because regressions concentrate in exactly the changes this covers (Gold models, Power BI datasets, Tier 1/2 changes), the evidence requirement makes review substantive rather than stylistic, and classifying violations as DQIs creates a feedback loop instead of normalized deviance.

### Option B: Checklist for Tier 1 only (set aside)

Its genuine advantage: concentrates the overhead on the highest-stakes changes and keeps routine work fast. Set aside because the most frequent change type — Tier 2 metric and report changes — is precisely where silent regressions reach stakeholders, so the exemption removes the protection where it is needed most.

### Option C: PR template item, best effort (set aside)

Its genuine advantage: near-zero overhead and no enforcement machinery to maintain. Set aside because an unenforced checklist decays to a reflexively-ticked box within weeks; it documents the aspiration while providing none of the guarantee.

## Consequences

**Positive**
- Stakeholder-facing numbers cannot change silently as a side effect of unrelated work.
- Review gains an evidence standard: "checklist complete, comparisons attached" is checkable, "looks fine" is not.
- The DQI classification makes regression frequency measurable — an input to the ADR-017 audit.

**Negative**
- Every Tier 1/2 change carries the cost of producing pre/post comparison evidence; small changes pay a fixed overhead.
- Pre/post comparison for large models has real compute cost and needs tooling (comparison queries or audit helpers) to stay tolerable.

**Accepted risks**
- The checklist verifies scope that was declared; a change whose author misjudges its blast radius can still regress an object nobody thought to compare. ADR-015 monitoring is the backstop for that case.

## Revisit trigger

Reopen if checklist overhead measurably slows delivery below SLA commitments (ADR-016) without a corresponding drop in regressions, or after the October 2026 audit (ADR-017) reports the first quarter of compliance data — whichever comes first.
