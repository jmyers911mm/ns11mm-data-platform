# ADR-012: Data Retention and Archival: Bronze Cost and Compliance Policy

**Status:** Proposed (drafted from the ADR Review working document; decision pending the Jeremy/Diana review session — **no option was marked recommended in the review doc; none is selected here**)
**Category:** Governance
**Date:** August 5, 2026
**Deciders:** Jeremy Myers (VP AI & Analytics); **Michael Cartier (CIO) sign-off required** given the institutional-sensitivity dimension
**Consulted:** Legal/Compliance [confirm whether an existing NS11MM retention schedule exists]
**Related:** ADR-007 (Bronze Immutability — deletion is an exception to the rule), ADR-019 (Single Source Database), Data Classification policy

> **Source note.** Drafted from the ADR Review working document (Part 2, ADR-012). Unlike the other proposed ADRs, the review doc marks **no recommended option** here; the options are presented for the session to choose, with Option A described as the leading candidate by ordering only. Option C's precondition — whether a Legal/Compliance retention schedule already exists — must be answered before the choice is made [confirm: Jeremy to check with Legal/Compliance].

## Context

Bronze append-only (ADR-007) means storage grows without bound, and Snowflake charges for storage. For NS11MM this also intersects with institutional sensitivity: some data carries legal or ethical retention obligations (attendance records, financial transactions, donor PII), and some data may need to be deleted on request or after a defined period. Deletion requests conflict directly with Bronze immutability and require the ADR-007 formal exception path — noting that a governed erasure mechanism (`gdpr_anonymize`, operating on the `source_database` per ADR-019) already exists for right-to-erasure and any policy here must align with it.

Without a policy, the team has no basis for archival decisions and no defense against indefinite storage cost growth.

What is not yet known: whether NS11MM Legal or Compliance maintains an existing retention schedule that this policy must inherit.

## Decision

**Pending the review session.** The decision must define: the default retention period for Bronze data by source type; the archival target when data ages out of active storage; the process for handling deletion requests (a formal ADR-007 exception, aligned with the existing `gdpr_anonymize` path); and the sign-off authority for retention policy changes (proposed: Jeremy Myers and Michael Cartier jointly).

## Options considered

### Option A: Tiered retention by data sensitivity (leading candidate, not yet selected)

Financial and donor data: 7-year retention (IRS compliance). Attendance and operational data: 3 years active, then archive to Azure Blob cold storage. Web/marketing analytics: 1 year active, delete after 2 years. PII deletion requests require a formal ADR-007 exception signed by Jeremy and Michael Cartier. Its strength: retention tracks actual obligation and cost, and the tiers map onto the existing Data Classification policy. Its cost: three lifecycles to operate and an archival pipeline to build and test (including restore).

### Option B: Indefinite retention with periodic cost review (not selected)

Its genuine advantage: nothing to build, nothing to delete wrongly — the safest posture against irreversible mistakes, and defensible while storage is a small fraction of spend (compute dominates the platform cost model per ADR-001). Set against it: storage cost grows without bound, and "we keep everything forever" is not a defensible answer to a donor deletion request or a compliance query.

### Option C: Inherit the existing NS11MM retention schedule uniformly (not selected)

Its genuine advantage: the institution's obligations are defined once, by the people accountable for them, and the platform simply complies — no parallel policy to defend. Set against it: it is only available if such a schedule exists (unconfirmed), and a uniform schedule ignores that Bronze source types differ materially in cost and sensitivity.

## Consequences

*(Of adopting any retention policy, versus the current absence of one.)*

**Positive**
- Archival and deletion decisions get a documented basis; storage cost gets a ceiling.
- Deletion requests follow a governed path instead of an improvised one, keeping ADR-007's guarantee intact.

**Negative**
- Any archival mechanism must be built, tested, and restore-verified — real engineering before go-live.
- A retention mistake is asymmetric: over-deletion is irreversible, and Bronze is the replay substrate for every downstream rebuild.

**Accepted risks**
- Until the session decides, the de facto policy is Option B (keep everything), accumulating cost and unaddressed obligation.

## Revisit trigger

Decide at the review session; this ADR must be Accepted **before the December 2026 go-live**. Once accepted, reopen if Legal/Compliance publishes or changes a retention schedule, if Snowflake storage cost exceeds a materiality threshold set at acceptance, or on the first PII deletion request that the chosen policy cannot cleanly answer — whichever comes first.
